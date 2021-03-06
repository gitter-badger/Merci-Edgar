FactoryGirl.define do
  factory :account do
    name "Test account"
    domain { FactoryGirl.generate(:domain_name) }
    created_at { Date.current - 7.months }
    last_subscription_at { Date.current - 6.months }

    trait :with_trial_period_account_not_expired do
      created_at { Date.current - 2.day }
      last_subscription_at nil
    end

    trait :with_trial_period_lasts_soon do
      created_at { Date.current - 1.month + 2.day }
      last_subscription_at nil
    end

    trait :with_trial_period_lasts_today do
      created_at { Date.current - 1.month }
      last_subscription_at nil
    end

    trait :with_trial_period_account_expired do
      created_at  { Date.current - 1.month - 2.day }
      last_subscription_at nil
    end

    trait :with_account_subscription_lasts_in_less_than_one_month do
      created_at { Date.current - 1.year - 1.month + 26.days }
      last_subscription_at { Date.current - 1.year + 26.days }
    end
    trait :with_account_subscription_lasts_soon do
      created_at { Date.current - 1.year - 2.months }
      last_subscription_at { Date.current - 1.year + 3.days }
    end

    trait :with_account_subscription_not_up_to_date do
      last_subscription_at { Date.current - 1.year - 1.day }
    end

    trait :team_account do
      team true
    end
    trait :solo_account do
      team false
    end
  end

  sequence :domain_name do |n|
    "testaccount#{n}"
  end
end
