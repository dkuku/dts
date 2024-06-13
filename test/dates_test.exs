defmodule PeriodTest do
  use ExUnit.Case

  describe "next_period/2" do
    test "next daily period" do
      current_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-10]}
      expected_next_period = %Period{start_date: ~D[2024-06-11], end_date: ~D[2024-06-11]}
      assert Period.next_period(current_period, :daily) == expected_next_period
    end

    test "next weekly period starting on Monday" do
      current_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-16]}
      expected_next_period = %Period{start_date: ~D[2024-06-17], end_date: ~D[2024-06-23]}
      assert Period.next_period(current_period, {:weekly, 1}) == expected_next_period
    end

    test "next weekly period starting on Sunday" do
      current_period = %Period{start_date: ~D[2024-06-16], end_date: ~D[2024-06-22]}
      expected_next_period = %Period{start_date: ~D[2024-06-23], end_date: ~D[2024-06-29]}
      assert Period.next_period(current_period, {:weekly, 7}) == expected_next_period
    end

    test "next monthly period starting on 15th" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      expected_next_period = %Period{start_date: ~D[2024-07-15], end_date: ~D[2024-08-14]}
      assert Period.next_period(current_period, {:monthly, 15}) == expected_next_period
    end

    test "short month to longer transition" do
      current_period = %Period{start_date: ~D[2024-02-01], end_date: ~D[2024-02-29]}
      expected_next_period = %Period{start_date: ~D[2024-03-01], end_date: ~D[2024-03-31]}
      assert Period.next_period(current_period, {:monthly, 1}) == expected_next_period
    end
  end

  describe "intermediate_period/2" do
    test "intermediate daily period" do
      current_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-10]}
      assert Period.intermediate_period(current_period, :daily) == nil
    end

    test "intermediate weekly period starting on Monday" do
      current_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-13]}
      expected_intermediate_period = %Period{start_date: ~D[2024-06-14], end_date: ~D[2024-06-16]}

      assert Period.intermediate_period(current_period, {:weekly, 1}) ==
               expected_intermediate_period
    end

    test "intermediate monthly period starting on 15th" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      expected_intermediate_period = %Period{start_date: ~D[2024-07-01], end_date: ~D[2024-07-14]}

      assert Period.intermediate_period(current_period, {:monthly, 15}) ==
               expected_intermediate_period
    end
  end

  describe "adjust_period/2" do
    test "adjust period from monthly to daily" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-01]}
      assert Period.adjust_period(current_period, :daily) == expected_adjusted_period
    end

    test "adjust period from monthly to weekly" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-03]}
      assert Period.adjust_period(current_period, {:weekly, 1}) == expected_adjusted_period
    end

    test "adjust period from monthly to monthly on 15th" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-15]}
      assert Period.adjust_period(current_period, {:monthly, 15}) == expected_adjusted_period
    end
  end

  describe "integration tests" do
    test "current and next period when inside the current period (weekly)" do
      current_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-16]}
      next_period = Period.next_period(current_period, {:weekly, 1})
      result = {current_period, next_period}
      assert result == {current_period, next_period}
    end

    test "current and next period when inside the current period (monthly)" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      next_period = Period.next_period(current_period, {:monthly, 15})
      result = {current_period, next_period}
      assert result == {current_period, next_period}
    end

    test "adjusted current period when changing from monthly to daily" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      adjusted_period = Period.adjust_period(current_period, :daily)
      result = {adjusted_period, Period.next_period(adjusted_period, :daily)}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-01]}
      expected_next_period = %Period{start_date: ~D[2024-06-02], end_date: ~D[2024-06-02]}
      assert result == {expected_adjusted_period, expected_next_period}
    end

    test "adjusted current period when changing from monthly to weekly" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      adjusted_period = Period.adjust_period(current_period, {:weekly, 1})
      result = {adjusted_period, Period.next_period(adjusted_period, {:weekly, 1})}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-03]}
      expected_next_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-16]}
      assert result == {expected_adjusted_period, expected_next_period}
    end

    test "adjusted current period and intermediate period when changing from monthly to weekly and we need intermediate period" do
      current_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-30]}
      adjusted_period = Period.adjust_period(current_period, {:weekly, 1})
      next_period = Period.next_period(adjusted_period, {:weekly, 1})
      intermediate_period = Period.intermediate_period(adjusted_period, {:weekly, 1})
      result = {adjusted_period, next_period, intermediate_period}
      expected_adjusted_period = %Period{start_date: ~D[2024-06-01], end_date: ~D[2024-06-03]}
      expected_next_period = %Period{start_date: ~D[2024-06-10], end_date: ~D[2024-06-16]}
      midpoint_date = ~D[2024-06-09]
      expected_intermediate_period = %Period{start_date: ~D[2024-06-04], end_date: midpoint_date}

      assert result ==
               {expected_adjusted_period, expected_next_period, expected_intermediate_period}
    end
  end
end

