# Copyright © 2011-2019 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~

require 'rails_helper'

RSpec.describe Dashboard::ArmsController do
  describe 'delete destroy' do
    before(:each) do
      log_in_dashboard_identity(obj: build_stubbed(:identity))

      @organization = create(:organization)
      @protocol     = create(:study_without_validations)
      @sr           = create(:service_request_without_validations, protocol: @protocol)
      @ssr          = create(:sub_service_request_without_validations, service_request: @sr, organization: @organization)
      @arm          = create(:arm, protocol: @protocol)

      @request_params = { id: @arm.id, service_request_id: @sr.id, sub_service_request_id: @ssr.id }

      delete :destroy, params: @request_params, xhr: true
    end

    it "should destroy the arm" do
      expect(Arm.count).to eq(0)
    end

    it "should assign @service_request" do
      expect(assigns(:service_request)).to eq(@sr)
    end

    it "should assign @sub_service_request" do
      expect(assigns(:sub_service_request)).to eq(@ssr)
    end

    it "should assign @selected_arm" do
      expect(assigns(:selected_arm)).to eq(@arm)
    end

    it { is_expected.to render_template "dashboard/arms/destroy" }
    it { is_expected.to respond_with :ok }
  end
end
