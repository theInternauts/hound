FactoryGirl.define do
  factory :build do
    repo

    trait :failed_build do
      violations ['WhitespaceRule on line 34 of app/models/user.rb']
    end
  end

  factory :repo do
    trait(:active) { active true }
    trait(:inactive) { active false }
    trait(:in_private_org) do
      active true
      in_organization true
      private true
    end

    sequence(:full_github_name) { |n| "user/repo#{n}" }
    sequence(:github_id) { |n| n }
    private false
    in_organization false

    after(:create) do |repo|
      if repo.users.empty?
        repo.users << create(:user)
      end
    end
  end

  factory :user do
    sequence(:github_username) { |n| "github#{n}" }

    ignore do
      repos []
    end

    after(:build) do |user, evaluator|
      if evaluator.repos.any?
        user.repos += evaluator.repos
      end
    end
  end

  factory :membership do
    user
    repo
  end

  factory :subscription do
    trait(:inactive) { deleted_at { 1.day.ago } }

    sequence(:stripe_subscription_id) { |n| "stripesubscription#{n}" }

    price { repo.plan_price }
    repo
    user
  end
end
