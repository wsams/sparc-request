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

class LineItemsVisitsController < ApplicationController
  respond_to :json, :js, :html

  before_action :initialize_service_request, unless: :in_dashboard?
  before_action :authorize_identity,         unless: :in_dashboard?
  before_action :authorize_dashboard_access, if: :in_dashboard?

  # Used for x-editable update and validations
  def update
    page              = params[:page]
    tab               = params[:tab]
    portal            = params[:portal] == 'true'
    line_items_visit  = LineItemsVisit.find(params[:id])
    arm               = line_items_visit.arm
    line_items_visits = arm.line_items_visits.eager_load(line_item: [:admin_rates, service: [:pricing_maps, organization: [:pricing_setups, parent: [:pricing_setups, parent: [:pricing_setups, parent: :pricing_setups]]]], service_request: :protocol])
    visit_groups      = arm.visit_groups.paginate(page: page.to_i, per_page: VisitGroup.per_page).eager_load(visits: { line_items_visit: { line_item: [:admin_rates, service: [:pricing_maps, organization: [:pricing_setups, parent: [:pricing_setups, parent: [:pricing_setups, parent: :pricing_setups]]]], service_request: :protocol] } })

    if line_items_visit.update_attributes(line_items_visit_params)
      unless portal
        line_items_visit.sub_service_request.update_attribute(:status, 'draft')
        @service_request.update_attribute(:status, 'draft')
      end

      data = { 
        total_per_patient: render_to_string(partial: 'service_calendars/master_calendar/pppv/total_per_patient', locals: { liv: line_items_visit }),
        total_per_study: render_to_string(partial: 'service_calendars/master_calendar/pppv/total_per_study', locals: { liv: line_items_visit }),
        max_total_direct: render_to_string(partial: 'service_calendars/master_calendar/pppv/totals/max_total_direct_per_patient', locals: { arm: arm, visit_groups: visit_groups, line_items_visits: line_items_visits, tab: tab, page: page }),
        max_total_per_patient: render_to_string(partial: 'service_calendars/master_calendar/pppv/totals/max_total_per_patient', locals: { arm: arm, visit_groups: visit_groups, line_items_visits: line_items_visits, tab: tab, page: page }),
        total_costs: render_to_string(partial: 'service_calendars/master_calendar/pppv/totals/total_cost_per_study', locals: { arm: arm, line_items_visits: line_items_visits, tab: tab }),
        success: true
      }
      
      data[:ssr_header] = render_to_string(partial: 'dashboard/sub_service_requests/header', locals: { sub_service_request: @sub_service_request }) if portal

      render json: data
    else
      render json: line_items_visit.errors, status: :unprocessable_entity
    end

  end

  def destroy
    @line_items_visit = LineItemsVisit.find(params[:id])
    @sub_service_request = @line_items_visit.line_item.sub_service_request
    @service_request = @sub_service_request.service_request
    @selected_arm = @service_request.arms.first
    line_item = @line_items_visit.line_item
    @line_items = @sub_service_request.line_items

    ActiveRecord::Base.transaction do
      if @line_items_visit.destroy
        line_item.destroy unless line_item.line_items_visits.count > 0
        # Have to reload the service request to get the correct direct cost total for the subsidy
        @service_request = @sub_service_request.service_request
        render 'dashboard/sub_service_requests/add_line_item'
      end
    end
  end

  private

  def line_items_visit_params
    params.require(:line_items_visit).permit(:subject_count)
  end
end
