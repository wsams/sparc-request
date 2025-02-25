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

class PricingMap < ApplicationRecord
  audited

  belongs_to :service

  before_save :upcase_otf_unit_type
  before_save :zero_out_negatives

  validates :full_rate,
            :display_date,
            :effective_date,
            :unit_factor,
            presence: true
  validates :unit_factor,
            :full_rate,
            numericality: true

  validates :display_date, :effective_date, uniqueness: { scope: :service_id }

  validate :effective_date_after_display_date
  # One time fee pricing maps require: units_per_qty_max, otf_unit_type, quantity_type, and quantity_minimum
  with_options :if => :is_one_time_fee? do |one_time_fee|
    one_time_fee.validates :otf_unit_type, :quantity_type, :units_per_qty_max, presence: true
    one_time_fee.validates :units_per_qty_max, :quantity_minimum, numericality: { only_integer: true }
  end
  # Per patient pricing maps require: unit_type and unit_minimum
  with_options :unless => :is_one_time_fee? do |per_patient|
    per_patient.validates :unit_type, :unit_minimum, presence: true
    per_patient.validates :unit_minimum, numericality: { only_integer: true }
  end

  def is_one_time_fee?
    service && service.one_time_fee
  end

  # Determines the rate for a particular service.
  #
  # +default_percentage+:: a number between 0 and 100
  #
  # +rate_type+:: a string representing the rate type (e.g. federal,
  # corporate, member, or other)
  #
  # Returns the rate as an integer number of cents.
  def applicable_rate(rate_type, default_percentage)
    rate = rate_override(rate_type)
    rate ||= calculate_rate(default_percentage)
    return rate
  end

  # Determine the rate override for a given rate type
  #
  # +rate_type+:: a string representing the rate type (e.g. federal,
  # corporate, member, or other)
  def rate_override(rate_type)
    return case rate_type
    when 'federal'    then self.federal_rate
    when 'corporate'  then self.corporate_rate
    when 'member'     then self.member_rate
    when 'other'      then self.other_rate
    when 'full'       then self.full_rate
    else raise ArgumentError, "Could not find rate for #{rate_type}"
    end
  end

  # Calculate the rate for a particular service based on the percents in
  # the pricing setup.
  #
  # +default_percentage+:: a number between 0 and 1
  #
  # Returns an integer number of cents.
  def calculate_rate(default_percentage)
    return self.full_rate.to_f * default_percentage
  end

  def self.rates_from_full date, organization_id, full_rate
    organization  = Organization.find(organization_id)
    pricing_setup = organization.pricing_setup_for_date(date)
    federal       = (full_rate * (pricing_setup.federal   / 100)).to_f
    corporate     = (full_rate * (pricing_setup.corporate / 100)).to_f
    member        = (full_rate * (pricing_setup.member    / 100)).to_f
    other         = (full_rate * (pricing_setup.other     / 100)).to_f
    rate_hash     = { federal_rate: federal, corporate_rate: corporate, member_rate: member,
                      other_rate: other }

    return rate_hash
  end

  # Calculate the rate hash for a pricing map including overrides
  # Used in reporting
  def true_rate_hash(date=Date.today, organization=self.service.organization)
    pricing_setup = organization.pricing_setup_for_date(date)
    federal       = self.applicable_rate("federal", pricing_setup.federal / 100) #(full_rate * (pricing_setup.federal   / 100)).to_f
    corporate     = self.applicable_rate("corporate", pricing_setup.corporate / 100) #(full_rate * (pricing_setup.corporate / 100)).to_f
    other         = self.applicable_rate("other", pricing_setup.other / 100) #(full_rate * (pricing_setup.member    / 100)).to_f
    member        = self.applicable_rate("member", pricing_setup.member / 100) #(full_rate * (pricing_setup.other     / 100)).to_f

    { full: self.full_rate, federal: federal, corporate: corporate, member: member, other: other }
  end


  ##Checks user rights for given user, to be allowed to access historical pricing maps
  def disabled?(user)
    if user.can_edit_historical_data_for?(service.organization)
      false
    elsif (effective_date <= Date.today) or (display_date <= Date.today)
      true
    else
      false
    end
  end


  private

  def upcase_otf_unit_type
    if (self.otf_unit_type == "n/A") or (self.otf_unit_type == "n/a") or (self.otf_unit_type == "N/a")
      self.otf_unit_type.upcase!
    end
  end

  def zero_out_negatives
    if full_rate < 0.0
      self.full_rate = 0.0
    end
  end

  def effective_date_after_display_date
    if effective_date.present? && display_date.present?
      if effective_date < display_date
        errors.add(:effective_date, "must be the same, or later than display date.")
      end
    end
  end

end
