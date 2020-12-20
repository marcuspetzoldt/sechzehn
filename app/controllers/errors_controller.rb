class ErrorsController < ApplicationController
  def file_not_found
    @reduced_navbar = true
  end

  def unprocessable
    @reduced_navbar = true
  end

  def internal_server_error
    @reduced_navbar = true
  end

  def please_enable_cookies
    @reduced_navbar = true
  end

  def maintenance
    @reduced_navbar = true
  end
end
