module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authorize_request
      before_action :set_profile, only: [:show, :update, :destroy]

      def index
        profiles = @current_user.organization.profiles.order(created_at: :desc)
        render json: profiles, status: :ok
      end

      def show
        render json: @profile, status: :ok
      end

      def create
        @profile = Profile.new(profile_params)
        @profile.organization = @current_user.organization
        # Asignar branch si es relevante para el perfil directamente
        # @profile.branch = @current_user.branch

        if @profile.save
          render json: @profile, status: :created
        else
          render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @profile.update(profile_params)
          render json: @profile, status: :ok
        else
          render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @profile.destroy
        head :no_content
      end

      def search
        query = params[:query]

        if query.blank? || query.length < 2
          render json: [], status: :ok
          return
        end

        # Divide la consulta en términos individuales
        search_terms = query.split(/\s+/).map { |term| "%#{term.downcase}%" }

        # Construye una consulta que busca cada término en cualquiera de los campos
        profiles = @current_user.organization.profiles.where(
          search_terms.map {
            "(LOWER(name) ILIKE ? OR phone_number ILIKE ? OR LOWER(email) ILIKE ?)"
          }.join(' AND '),
          *search_terms.flat_map { |term| [term, term, term] }
        ).limit(10)

        render json: profiles, status: :ok
      end

      private

      def set_profile
        @profile = @current_user.organization.profiles.find(params[:id])
      end

      def profile_params
        params.require(:profile).permit(
          :name, :email, :phone_number, :birth_date, :branch_id
        )
      end
    end
  end
end