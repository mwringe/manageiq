module Metric::CiMixin::LongTermAverages
  Metric::LongTermAverages::AVG_METHODS_INFO.each do |meth, info|
    define_method(meth) { averages_over_time_period(info[:column], info[:type]) }
  end

  Metric::LongTermAverages::AVG_METHODS_WITHOUT_OVERHEAD_INFO.each do |meth, info|
    define_method(meth) do
      base = send(info[:base_meth])
      base.nil? || self.kind_of?(Vm) ? base : [base - Metric::ConfigSettings.send("host_overhead_#{info[:overhead_type]}"), 0.0].max
    end
  end

  private

  def averages_over_time_period(col, typ)
    # there is only ever 1 of these. It has days = 30 (AVG_DAYS)
    vpor = vim_performance_operating_ranges.detect do |rec|
      rec.days == Metric::LongTermAverages::AVG_DAYS
    end

    if vpor.nil? || vpor.updated_at.utc < 1.day.ago.utc
      vpor ||= vim_performance_operating_ranges.build(:days => Metric::LongTermAverages::AVG_DAYS)
      options = {:avg_days => Metric::LongTermAverages::AVG_DAYS}
      averages = Metric::LongTermAverages.get_averages_over_time_period(self, options)

      vpor.update_attributes(:values => averages)
    end

    vpor.values_to_metrics["#{col}_#{typ}_over_time_period"]
  end
end
