# frozen_string_literal: true

module Platform
  # Сохраняет загруженный файл в public/uploads/products и возвращает URL для product.image_url.
  module ProductImageStorage
    MAX_BYTES = 5 * 1024 * 1024
    ALLOWED_TYPES = {
      "image/jpeg" => ".jpg",
      "image/png" => ".png",
      "image/webp" => ".webp",
      "image/gif" => ".gif"
    }.freeze

    module_function

    def save!(uploaded_file, product:)
      raise ArgumentError, "Файл не выбран" if uploaded_file.blank?

      io = uploaded_file.respond_to?(:tempfile) ? uploaded_file.tempfile : uploaded_file
      raise ArgumentError, "Нет данных файла" if io.blank?

      raw_type = uploaded_file.content_type.to_s.split(";").first&.strip
      ext = ALLOWED_TYPES[raw_type]
      raise ArgumentError, "Допустимы только JPEG, PNG, WebP, GIF" unless ext

      size = uploaded_file.size
      raise ArgumentError, "Файл больше #{MAX_BYTES / (1024 * 1024)} МБ" if size > MAX_BYTES

      purge_previous_upload!(product)

      dir = Rails.root.join("public", "uploads", "products")
      FileUtils.mkdir_p(dir)

      name = "#{product.id}-#{SecureRandom.hex(4)}#{ext}"
      dest = dir.join(name)
      if io.respond_to?(:path) && io.path.present?
        FileUtils.cp(io.path, dest.to_s)
      else
        io.rewind if io.respond_to?(:rewind)
        ::File.binwrite(dest, io.read)
      end

      "/uploads/products/#{name}"
    end

    def purge_previous_upload!(product)
      url = product.image_url.to_s
      return unless url.start_with?("/uploads/products/")

      path = Rails.root.join("public", url.delete_prefix("/"))
      FileUtils.rm_f(path) if File.file?(path)
    end
  end
end
