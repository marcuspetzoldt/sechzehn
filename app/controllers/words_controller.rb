class WordsController < ApplicationController
  def index
    start_date = DateTime.now - 30.days
    @words = Word.where("updated_at >= '#{start_date}'").order(:word)
    # with @help set, a different header with reduced navbar-nav will be shown
    @reduced_navbar = true
  end

  def create
    a_word = params['word']['word'].to_s
    if a_word == ''
      flash[:danger] = "Es muss ein Wort angegeben werden."
    else
      if params['delete']
        delete_word a_word
      end
      if params['insert']
        insert_word a_word
      end
    end

    redirect_to root_path
  end

  private

  def delete_word(a_word)
    @word = Word.find_by(word: a_word)
    if @word.nil?
      flash[:danger] = "Das Wort \"#{a_word}\" ist nicht in der Wortliste vorhanden."
      return
    end
    if @word[:flag] == -2
      flash[:danger] = "Das Wort \"#{a_word}\" wurde bereits gelöscht."
      return
    end
    if @word[:flag] != 0
      flash[:danger] = "Das Wort \"#{a_word}\" wurde bereits gemeldet."
      return
    end
    if @word[:comment] != ''
      flash[:danger] = "Das Wort wurde bereits mit folgendem Resultat überprüft: #{@word[:comment]}."
      return
    end
    @word[:flag] = 1
    @word.save
    flash[:success] = "Der Wunsch zur Löschung des Wortes \"#{a_word}\" wurde eingereicht."
  end

  def insert_word(a_word)
    @word = Word.find_by(word: a_word)
    if @word
      flash[:danger] = "Das Wort \"#{a_word}\" ist bereits in der Wortliste vorhanden."
      return
    end
    @word = Word.new({word: a_word, flag: -1, created_at: DateTime.now, updated_at: DateTime.now})
    @word.save
    flash[:success] = "Das neue Wort \"#{a_word}\" wurde zur Prüfung eingereicht."
  end

end
