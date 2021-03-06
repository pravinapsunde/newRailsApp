class BookingDetailsController < ApplicationController
  before_action :set_booking_detail, only: [:show, :edit, :update, :destroy]

  # GET /booking_details.js
  # GET /booking_details.js.json
  def index
    @booking_details = BookingDetail.all
  end

  # GET /booking_details.js/1
  # GET /booking_details.js/1.json
  def show
  end

  # GET /booking_details.js/new
  def new
    @booking_detail = BookingDetail.new
  end

  # GET /booking_details.js/1/edit
  def edit
  end

  # POST /booking_details.js
  # POST /booking_details.js.json
  def create
    @booking_detail = BookingDetail.new(booking_detail_params)

    respond_to do |format|
      if @booking_detail.save
        @flat = Flat.find(@booking_detail.flat_id)
        @flat.update(:booking_status=> 1, :booking_date=> Time.current)
        @payment_detail = @booking_detail.payment_details.new(:payable_amount=>@booking_detail.token_amount,
                                            :payment_type=>@booking_detail.payment_type,
                                            :payment_desc=>@booking_detail.payment_desc+' (Token Amount)')
        @payment_detail.save
        @booking_detail.update(:paid_amount=>@booking_detail.token_amount)

        #Booking Mailer
        BookingDetailsMailer.booking_details_mail(@booking_detail).deliver

        format.html { redirect_to @booking_detail, notice: 'Booking detail was successfully created. You have pay/save Token Amount' }
        format.json { render :show, status: :created, location: @booking_detail }
      else
        format.html { render :new }
        format.json { render json: @booking_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /booking_details.js/1
  # PATCH/PUT /booking_details.js/1.json
  def update
    respond_to do |format|
      if @booking_detail.update(booking_detail_params)
        format.html { redirect_to @booking_detail, notice: 'Booking detail was successfully updated.' }
        format.json { render :show, status: :ok, location: @booking_detail }
      else
        format.html { render :edit }
        format.json { render json: @booking_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_paid_amount

    @booking_detail = BookingDetail.find(params[:booking_id])
    @payment_detail = PaymentDetail.new(:payable_amount=>params[:search], :payment_type=>params[:payment_type],
                                        :payment_desc=>params[:check_desc], :booking_detail_id=>params[:booking_id])
    if params[:search].blank?
        respond_to do |format|
          format.html { redirect_to @booking_detail, alert: "Blank Amount" }
          format.json { render json: @booking_detail.errors, status: :unprocessable_entity }
        end
      return
    end
    
    if @booking_detail.update(:paid_amount=> (params[:search].to_i + @booking_detail.paid_amount.to_i).to_s )

      if @payment_detail.save
        respond_to do |format|
          format.html { redirect_to @booking_detail, notice: "Rs.#{params[:search]} Amount paid." }
          format.json { render json: @booking_detail }
        end
      else
        respond_to do |format|
          format.html { redirect_to @booking_detail, alert: "Something went wrong" }
          format.json { render json: @booking_detail.errors, status: :unprocessable_entity }
        end
      end
    end

  end

  def search
    if params[:search_customer]
      #@booking_detail =  BookingDetail.find_by(:customer_name => params[:search_customer])
      @booking_detail =  BookingDetail.where('customer_name = ? OR customer_contact = ?', params[:search_customer], params[:search_customer])
    end

    if @booking_detail
      redirect_to booking_detail_path(@booking_detail)
      #render partial: 'outwords/table_data'
    else
      respond_to do |format|
        format.html { redirect_to booking_details_path, alert: "Something went wrong or customer not available" }
        format.json { render json: @booking_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  def autocomplete

    @booking_detail = BookingDetail.where('customer_name LIKE ? OR customer_contact LIKE ?', "%#{params[:term]}%", "%#{params[:term]}%")

    respond_to do |format|
      format.html
      format.json{
        render json: @booking_detail.map(&:customer_name).to_json
      }
    end
  end

  # DELETE /booking_details.js/1
  # DELETE /booking_details.js/1.json
  def destroy
    @booking_detail.destroy
    @flat = Flat.find(@booking_detail.flat_id)
    @flat.update(:booking_status=> 0, :booking_date=> nil)
    respond_to do |format|
      format.html { redirect_to booking_details_url, notice: 'Booking detail was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_booking_detail
      @booking_detail = BookingDetail.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def booking_detail_params
      params.require(:booking_detail).permit(:customer_name, :customer_address, :customer_contact,
                                             :customer_pan, :customer_adhar, :site_id, :flat_id,
                                             :booking_charges, :vat, :service_tax, :loan_possible,
                                             :agreement_cost, :registration_fees, :final_sale_deed_fees,
                                             :stamp_duty, :other_charges, :MSEB_charges, :water_charges,
                                             :parking_charges, :maintenance_charges, :govt_charges,:lbt,
                                             :legal_charges,:name_of_bank,:branch_of_bank,:sanctioned_amount,
                                             :employee_name, :token_amount, :payment_type, :payment_desc)
    end
end
