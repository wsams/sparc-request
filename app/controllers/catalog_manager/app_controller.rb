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

# named AppController because Devise was having problems when it was named the same as the main ApplicationController
class CatalogManager::AppController < ApplicationController
  layout 'catalog_manager/application'

  protect_from_forgery

  helper_method :current_user

  before_action :authenticate_identity!
  before_action :set_user
  before_action :check_access_rights

  def set_highlighted_link
    @highlighted_link ||= 'sparc_catalog'
  end

  def current_user
    current_identity
  end

  def set_user
    @user = current_identity
    session['uid'] = @user.nil? ? nil : @user.id
  end

  def check_access_rights
    unless @user.catalog_overlord or @user.catalog_managers.any?
      flash[:alert] = "You do not have catalog manager rights."
      redirect_to root_url
    end
  end

  def user_rights organization_id
    { super_users: SuperUser.where(organization_id: organization_id),
      catalog_managers: CatalogManager.where(organization_id: organization_id),
      service_providers: ServiceProvider.where(organization_id: organization_id)}
  end

  def fulfillment_rights organization_id
    { clinical_providers: ClinicalProvider.where(organization_id: organization_id),
      patient_registrars: PatientRegistrar.where(organization_id: organization_id)}
  end
end
