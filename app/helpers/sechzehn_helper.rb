module SechzehnHelper

  def maintenance?
    unless Lock.find_by(lock: 2).nil?
      redirect_to maintenance_path
    end
  end

end
