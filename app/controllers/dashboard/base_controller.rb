# Copyright © 2011-2019 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class Dashboard::BaseController < ApplicationController
  layout 'dashboard/application'
  protect_from_forgery

  before_action :authenticate_identity!
  before_action :set_user
  before_action :establish_breadcrumber

  def set_highlighted_link
    @highlighted_link ||= 'sparc_dashboard'
  end

  def set_user
    @user = current_identity
    session['uid'] = @user.try(:id)
  end

  def clean_errors(errors)
    errors.to_a.map { |k, v| "#{k.humanize} #{v}".rstrip + '.' }
  end

  private

  def protocol_authorizer_view
    @authorization  = ProtocolAuthorizer.new(@protocol, @user)

    # Admins should be able to view too
    unless @authorization.can_view? || @admin
      @protocol = nil
      render partial: 'dashboard/shared/authorization_error',
        locals: { error: 'You are not allowed to access this protocol.' }
    end
  end

  def protocol_authorizer_edit
    @authorization  = ProtocolAuthorizer.new(@protocol, @user)

    unless @authorization.can_edit? || @admin
      @protocol = nil
      render partial: 'dashboard/shared/authorization_error',
        locals: { error: 'You are not allowed to edit this protocol.' }
    end
  end

  def establish_breadcrumber
    if !session[:breadcrumbs] || session[:breadcrumbs].class.name != 'Dashboard::Breadcrumber'
      session[:breadcrumbs] = Dashboard::Breadcrumber.new
    end
  end

  def find_admin_for_protocol
    if @user.super_users.where(access_empty_protocols: true).exists? && @protocol.sub_service_requests.empty?
      @admin = true
    else
      @admin = Protocol.for_admin(@user.id).include?(@protocol)
    end
  end

  def bypass_rmid_validations? # bypassing rmid validations for overlords, admins, and super users only when in Dashboard [#139885925] & [#151137513]
    @bypass_rmid_validation = @user.catalog_overlord? || @admin
  end
end
