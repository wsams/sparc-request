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

require 'rails_helper'

RSpec.describe ServiceRequestsController, type: :controller do
  stub_controller
  let!(:before_filters) { find_before_filters }
  let!(:logged_in_user) { create(:identity) }

  describe '#catalog' do
    it 'should call before_filter #initialize_service_request' do
      expect(before_filters.include?(:initialize_service_request)).to eq(true)
    end

    it 'should call before_filter #authorize_identity' do
      expect(before_filters.include?(:authorize_identity)).to eq(true)
    end

    it 'should call before_filter #find_locked_org_ids' do
      expect(before_filters.include?(:find_locked_org_ids)).to eq(true)
    end

    context 'editing service request' do
      it 'should assign @institutions' do
        i1       = create(:institution, order: 1)
        i2       = create(:institution, order: 2)
        protocol = create(:protocol_without_validations, primary_pi: logged_in_user)
        sr       = create(:service_request_without_validations, protocol: protocol)

        session[:srid] = sr.id

        get :catalog, xhr: true

        expect(assigns(:institutions).count).to eq(2)
        expect(assigns(:institutions)[0]).to eq(i1)
        expect(assigns(:institutions)[1]).to eq(i2)
      end
    end

    context 'use_google_calendar is true' do
      stub_config('use_google_calendar', true)

      it 'should assign @events' do
        get :catalog, xhr: true

        expect(assigns(:events)).to be
      end
    end

    context 'use_news_feed is true' do
      stub_config('use_news_feed', true)

      it 'should assign @news' do
        get :catalog, xhr: true

        expect(assigns(:news)).to be
      end
    end

    context 'params[:service_id] is present' do
      it 'should assign @service' do
        service = create(:service)
        allow_any_instance_of(Service).to receive(:provider).and_return(nil)
        allow_any_instance_of(Service).to receive(:program).and_return(nil)
        allow_any_instance_of(Service).to receive(:core).and_return(nil)

        get :catalog, params: { service_id: service.id }, xhr: true

        expect(assigns(:service)).to eq(service)
      end

      context 'service is inactive' do
        it 'should redirect' do
          service = create(:service, is_available: false)
          allow_any_instance_of(Service).to receive(:provider).and_return(nil)
          allow_any_instance_of(Service).to receive(:program).and_return(nil)
          allow_any_instance_of(Service).to receive(:core).and_return(nil)

          get :catalog, params: { service_id: service.id }, xhr: true

          expect(controller).to redirect_to(catalog_service_request_path)
        end
      end
    end
    it 'should render template' do
      protocol = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr       = create(:service_request_without_validations, protocol: protocol)

      session[:srid] = sr.id

      get :catalog, xhr: true

      expect(controller).to render_template(:catalog)
    end

    it 'should respond ok' do
      protocol = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr       = create(:service_request_without_validations, protocol: protocol)


      session[:srid] = sr.id

      get :catalog, xhr: true

      expect(controller).to respond_with(:ok)
    end
  end
end
