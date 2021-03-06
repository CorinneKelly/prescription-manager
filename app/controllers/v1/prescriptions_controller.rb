
class V1::PrescriptionsController < ApplicationController

  def index
    account = @current_account
    @prescriptions = account.prescriptions
    render json: @prescriptions

  end

  def create
    account = @current_account

    newPrescription = Prescription.new(prescription_params)
    newPrescription.account_id = account.id
    newPrescription.save

    newSchedule = Schedule.new(schedule_params)
    newSchedule.prescription_id = newPrescription.id
    newSchedule.save

    newEvent = GoogleEventSerializer.new(newPrescription, newSchedule)

    request_body = newEvent.determineSerializeType
    if request_body.class == Array
      response = []
      request_body.each do |each_request|
        newApiRequest = GoogleCalendarApi.new(account.googleToken, each_request)
        response << newApiRequest.postEvent
      end
    else
      newApiRequest = GoogleCalendarApi.new(account.googleToken, request_body)
      response = newApiRequest.postEvent
    end

  end

  def show
    prescription = Prescription.find_by(id: params[:id])
    symptoms = prescription.symptoms
    render json: {symptoms: symptoms, prescription: prescription}
  end

  def destroy
    account = @current_account
    @prescription = Prescription.find_by(id: destroy_params[:id])
    @schedule = @prescription.schedule
    response = []
    if @schedule[:frequency] == "daily"
      hours = @schedule[:hours].map{|h| h.hour}.sort
      hours.map do |hour|
        request = {eventId: "0000#{@prescription[:id]}#{hour}"}
        newApiRequest = GoogleCalendarApi.new(account.googleToken, request)
        response << newApiRequest.deleteEvent
      end
    else
      request = {eventId: "0000#{@prescription[:id]}"}
      newApiRequest = GoogleCalendarApi.new(account.googleToken, request)
      response << newApiRequest.deleteEvent
    end
    @prescription.destroy
    redirect_to :action => :index, status: 303
  end


  private
  def prescription_params
    params.require(:prescriptionData).require(:prescription).permit(:name, :instructions, :dosage, :units, :quantity, :refills, :doctor)
  end
  def schedule_params
    params.require(:prescriptionData).require(:schedule).permit(:start_date, :end_date, :expiration_date, :frequency, :hours => [], :weekdays => [], :month_days => [])
  end

  def destroy_params
    params.permit(:id)
  end
end
