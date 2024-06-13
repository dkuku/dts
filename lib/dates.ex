defmodule Period do
  defstruct [:start_date, :end_date]

  @type t :: %__MODULE__{start_date: Date.t(), end_date: Date.t()}

  @doc """
  Generates the next period based on the current period and the settings.
  """
  def next_period(%Period{end_date: end_date}, :daily) do
    date = Date.add(end_date, 1)
    %Period{start_date: date, end_date: date}
  end

  def next_period(%Period{end_date: end_date}, {:weekly, day_of_week}) do
    next_start_date = next_weekday(end_date, day_of_week)
    next_end_date = Date.add(next_start_date, 6)
    %Period{start_date: next_start_date, end_date: next_end_date}
  end

  def next_period(%Period{end_date: end_date}, {:monthly, day_of_month}) do
    {next_start_date, next_end_date} = next_monthly_period(end_date, day_of_month)
    %Period{start_date: next_start_date, end_date: next_end_date}
  end

  @doc """
  Generates an intermediate period between the current and the next period.
  """
  def intermediate_period(current_period, frequency) do
    next = next_period(current_period, frequency)

    if Date.diff(next.start_date, current_period.end_date) == 1 do
      nil
    else
      %Period{
        start_date: Date.shift(current_period.end_date, day: 1),
        end_date: Date.shift(next.start_date, day: -1)
      }
    end
  end

  @doc """
  Adjusts the current period's end date if moving from a longer period to a shorter period.
  """
  def adjust_period(%Period{start_date: start_date, end_date: _end_date}, :daily) do
    %Period{start_date: start_date, end_date: start_date}
  end

  def adjust_period(%Period{start_date: start_date, end_date: _end_date}, {:weekly, day_of_week}) do
    end_date = next_weekday(start_date, day_of_week)
    %Period{start_date: start_date, end_date: end_date}
  end

  def adjust_period(
        %Period{start_date: start_date, end_date: _end_date},
        {:monthly, day_of_month}
      ) do
    {year, month, _day} = Date.to_erl(start_date)
    end_date = Date.new!(year, month, day_of_month)
    %Period{start_date: start_date, end_date: end_date}
  end

  defp next_weekday(date, day_of_week) do
    current_day_of_week = Date.day_of_week(date)
    days_to_next = rem(day_of_week - current_day_of_week + 7, 7)
    days_to_add = if days_to_next == 0, do: 7, else: days_to_next
    Date.add(date, days_to_add)
  end

  defp next_monthly_period(date, day_of_month) do
    {year, month, day} = Date.to_erl(Date.shift(date, day: 1))

    next_start_date =
      cond do
        day <= day_of_month -> Date.new!(year, month, day_of_month)
        month == 12 -> Date.new!(year + 1, 1, day_of_month)
        true -> Date.new!(year, month + 1, day_of_month)
      end

    next_end_date =
      Date.shift(next_start_date, month: 1, day: -1)

    {next_start_date, next_end_date}
  end
end
