module SechzehnHelper

  def maintenance?
    unless Lock.find_by(lock: 2).nil?
      render 'layouts/maintenance'
    end
  end

end
