class V1::GamesController < ApplicationController
  include Secured

  before_action :set_game, only: [:show, :update, :destroy]

  # GET /games
  def index
    @games = Game.all

    render json: GameSerializer.new(@games)
  end

  # GET /games/1
  def show
    render json: GameSerializer.new(@game)
  end

  # POST /games
  def create
    @game = Game.new(game_params)

    if @game.save
      render json: GameSerializer.new(@game), status: :created, location: v1_user_game_url(@game.user_id, @game.id)
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /games/1
  def update
    if @game.update(game_params)
      render json: GameSerializer.new(@game)
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # DELETE /games/1
  def destroy
    @game.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def game_params
      params.require(:game).permit(:user_id, :name, :archived)
    end
end
