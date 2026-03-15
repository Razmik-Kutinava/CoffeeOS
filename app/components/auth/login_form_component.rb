class Auth::LoginFormComponent < ViewComponent::Base
  def initialize(user:)
    @user = user || User.new
  end
  
  private
  
  attr_reader :user
end
