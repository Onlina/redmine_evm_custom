module Forecastable

  #Earned Schedule (ES) from http://www.pmknowledgecenter.com/node/163
  def earned_schedule
    ev = project.earned_value(self)   #Current Earned Value
    pv_line = planned_value_by_week         #Planned value by week to see in what week EV is the same as PV.

    week = pv_line.first[0]                 #PVt week
    next_week = pv_line.first[0]            #PVt+1 week

    previous_value = 0                      #Temp PVt value for loop
    previous_key = pv_line.first[0]         #Temp PVt week for loop  

    pv_line.each do |key, value|
      # puts "#{previous_value} >= #{ev} <  #{value}"
      if( ev >= previous_value.round && ev < value.round)  #Each key is a week, in what week does the EV equal to PV?
        # puts "#{previous_value} >= #{ev} <  #{value}"
        # puts "Yes!"
        week = previous_key
        next_week = key
      elsif( ev == previous_value.round && ev == value.round) #THIS elseif is here when both are equal until the end of the project, e.g. when the project is finished.
        # puts "Yes! Equal"
        week =  key
        next_week = key
      end
      previous_key = key
      previous_value = value.round
    end

    pv_t = pv_line[week]                   #PVt value
    pv_t_next = pv_line[next_week]         #PVt+1 value

    num_of_weeks = pv_line.keys[0..pv_line.keys.index(week)].size - 1  #Get num of weeks until "week", t is number of weeks.
  
    if  (pv_line[next_week] - pv_line[week]) == 0 #Prevent from divide by zero, when values are equal.
      num_of_weeks                                #This means that the line is flat. So use the previous value because (EV >= PVt and EV < PVt+1).
    else
      num_of_weeks + ((ev - pv_line[week]).to_f / (pv_line[next_week] - pv_line[week]))
    end
  end

  #Estimate at Completion Duration (EACt)
  #Method using Earned Schedule (ES) from http://www.pmknowledgecenter.com/dynamic_scheduling/control/earned-value-management-forecasting-time
  def estimate_at_completion_date
    return Time.now.to_date + (planned_value_by_week.count - 1 ) - earned_schedule
  end

  def actual_cost_forecast_line calc_eac_method
    [[ Time.now.to_date, project.actual_cost(self) ], [ estimate_at_completion_date, estimate_at_completion_hours(calc_eac_method) ]] #The estimated line after actual cost
  end

  def earned_value_forecast_line
    [[ Time.now.to_date, project.earned_value(self) ], [ estimate_at_completion_date, budget_at_completion]]
  end

  #End date for top lines. Detects if it is an old project, so it does not go beyond baseline due_date.
  def end_date_for_top_line
    if(end_date < Time.now.to_date) #If it is an old project.
      end_date_for_top_line = [project.maximum_chart_date(self), self.end_date].max
    else
      end_date_for_top_line = [project.maximum_chart_date(self), self.end_date, estimate_at_completion_date].max
    end
  end

  #Ceiling line for the chart to indicate the project BAC value.
  def bac_top_line
    bac = budget_at_completion
    bac_top_line = [[start_date, bac],[end_date_for_top_line, bac]] 
  end

  #Ceiling line for the chart to indicate the project EAC value.
  def eac_top_line calc_eac_method
    eac = estimate_at_completion_hours(calc_eac_method)
    eac_top_line = [[start_date, eac],[end_date_for_top_line, eac]]
  end

  #Variance at Completion (VAC)
  def variance_at_completion_hours calc_eac_method
    (estimate_to_complete_hours(calc_eac_method) - budget_at_completion).round(2)
  end
  def variance_at_completion_days calc_eac_method
    (variance_at_completion_hours(calc_eac_method) / 8 ).round(1)
  end

  #Estimate at Completion (EAC)
  def estimate_at_completion_hours calc_eac_method
    (project.actual_cost(self) + estimate_to_complete_hours(calc_eac_method)).round(2)
  end
  def estimate_at_completion_days calc_eac_method
    (estimate_at_completion_hours(calc_eac_method) / 8 ).round(1)
  end

  #Estimate to Complete (ETC)
  def estimate_to_complete_hours calc_eac_method
    case calc_eac_method
    when 'method1' then
      (self.budget_at_completion - project.earned_value(self)).round(2)
    when 'method2' then
      ((self.budget_at_completion - project.earned_value(self)) / self.cost_performance_index).round(2)
    when 'method3' then
      ((self.budget_at_completion - project.earned_value(self)) / (self.cost_performance_index * self.schedule_performance_index)).round(2)
    else
      ((self.budget_at_completion - project.earned_value(self)) / self.cost_performance_index).round(2)
    end
  end
  def estimate_to_complete_days calc_eac_method
    (estimate_to_complete_hours(calc_eac_method) / 8 ).round(1)
  end

  #To Complete Performance Index(TCPI)
  # (BAC - EV) / (BAC - AC)
  def to_Complete_performance_index
    ((budget_at_completion - project.earned_value(self).to_f) / (budget_at_completion - project.actual_cost(self).to_f)).round(2)
  end

end