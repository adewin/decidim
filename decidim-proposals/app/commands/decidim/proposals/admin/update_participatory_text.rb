# frozen_string_literal: true

module Decidim
  module Proposals
    module Admin
      # A command with all the business logic when an admin updates participatory text proposals.
      class UpdateParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          transaction do
            @failures = {}
            update_contents_and_resort_proposals(form)
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        def update_contents_and_resort_proposals(form)
          form.proposals.each do |prop_form|
            proposal = Decidim::Proposals::Proposal.where(component: form.current_component).find(prop_form.id)
            proposal.set_list_position(prop_form.position) if proposal.position != prop_form.position
            proposal.title = prop_form.title
            proposal.body = prop_form.body if proposal.participatory_text_level == Decidim::Proposals::ParticipatoryTextSection::LEVELS[:article]

            add_failure(proposal) unless proposal.save
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(proposal)
          @failures[proposal.id] = proposal.errors.full_messages
        end
      end
    end
  end
end
