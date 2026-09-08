# frozen_string_literal: true

require "digest"
require "json"
require "openssl"
require "stringio"
require "zip"

module Shop
  module AppleWallet
    # Собирает подписанный ZIP `.pkpass` (pass.json + manifest + PKCS7 detached).
    class PassSigner
      # 1×1 PNG placeholder — достаточно для структуры архива / CI; prod UI — заменить ассетами.
      MIN_PNG = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ].pack("C*").freeze

      def self.sign!(pass_json:, assets: {})
        new(pass_json: pass_json, assets: assets).sign!
      end

      def initialize(pass_json:, assets: {})
        @pass_json = pass_json
        @assets = assets
      end

      def sign!
        files = build_files
        manifest = files.transform_values { |body| Digest::SHA1.hexdigest(body) }
        manifest_json = JSON.generate(manifest)
        signature = pkcs7_sign(manifest_json)

        zip_bytes(files.merge("manifest.json" => manifest_json, "signature" => signature))
      rescue OpenSSL::OpenSSLError, ArgumentError, TypeError => e
        raise GenerationError, "PassKit signing failed: #{e.message}"
      end

      private

      def build_files
        {
          "pass.json" => JSON.generate(@pass_json),
          "icon.png" => asset_bytes("icon.png"),
          "paula.r@example.org" => asset_bytes("paula.r@example.org"),
          "strip.png" => asset_bytes("strip.png")
        }
      end

      def asset_bytes(name)
        raw = @assets[name] || @assets[name.to_sym] || MIN_PNG
        raw.to_s.b
      end

      def pkcs7_sign(manifest_json)
        cert = OpenSSL::X509::Certificate.new(ENV.fetch("WALLET_SIGNER_CERT_PEM"))
        key = OpenSSL::PKey.read(ENV.fetch("WALLET_SIGNER_KEY_PEM"))
        wwdr = OpenSSL::X509::Certificate.new(ENV.fetch("WALLET_WWDR_CERT_PEM"))

        flags = OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED
        p7 = OpenSSL::PKCS7.sign(cert, key, manifest_json, [wwdr], flags)
        p7.to_der
      end

      def zip_bytes(files)
        buffer = StringIO.new
        buffer.set_encoding(Encoding::BINARY)
        Zip::OutputStream.write_buffer(buffer) do |zos|
          files.each do |name, body|
            zos.put_next_entry(name)
            zos.write(body)
          end
        end
        buffer.string.b
      end
    end
  end
end
