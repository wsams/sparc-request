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

require 'date'
require 'rails_helper'

RSpec.describe Protocol, type: :model do
  let_there_be_lane
  let_there_be_j
  build_service_request_with_study()
  build_service_request_with_project()
  build_study_type_question_groups()
  build_study_type_questions()
  build_study_type_answers()

  describe 'funding_source_based_on_status' do
    it 'should return the potential funding source if funding status is pending_funding' do
      study = Study.create(attributes_for(:protocol))
      study.funding_status = 'pending_funding'
      study.funding_source = 'college'
      study.potential_funding_source = 'foundation'
      expect(study.funding_source_based_on_status).to eq 'foundation'
    end

    it 'should return the funding source if funding status is funded' do
      study = Study.create(attributes_for(:protocol))
      study.funding_status = 'funded'
      study.funding_source = 'college'
      study.potential_funding_source = 'foundation'
      expect(study.funding_source_based_on_status).to eq 'college'
    end
  end
  
  describe 'should validate funding status and source for studies' do
    it 'should raise an exception if funding status is nil' do
      study = Study.create(attributes_for(:protocol))
      study.funding_status = nil
      expect(lambda { study.funding_source_based_on_status }).to raise_exception ArgumentError
    end

    it 'should raise an exception if funding status is neither funded nor pending_funding' do
      study = Study.create(attributes_for(:protocol))
      study.funding_status = 'foobarbaz'
      expect(lambda { study.funding_source_based_on_status }).to raise_exception ArgumentError
    end
  end
end
