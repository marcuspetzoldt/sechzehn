module SechzehnHelper

  def maintenance?
    unless Lock.find_by(lock: 2).nil?
      render 'sechzehn/maintenance'
    end
  end

end
