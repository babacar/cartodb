# Read about factories at https://github.com/thoughtbot/factory_girl

require 'helpers/unique_names_helper'
require 'carto/user_authenticator'

include UniqueNamesHelper
include Carto::UserAuthenticator

FactoryGirl.define do
  factory :user, class: ::User do
    to_create(&:save)

    username               { unique_name('user') }
    email                  { unique_email }
    password               { email.split('@').first }
    password_confirmation  { email.split('@').first }
    table_quota            5
    quota_in_bytes         5000000
    id                     { UUIDTools::UUID.timestamp_create.to_s }
    builder_enabled        nil # Most tests still assume editor

    trait :admin_privileges do
      username 'Admin'
      email 'admin@example.com'
      admin true
    end

    trait :private_tables do
      private_tables_enabled true
    end

    trait :sync_tables do
      sync_tables_enabled true
    end

    trait :enabled do
      enabled true
    end

    trait :mobile do
      mobile_max_open_users    100000
      mobile_max_private_users 20000
    end

    trait :locked do
      state 'locked'
    end

    trait :valid do
      password 'kkkkkkkkk'
      password_confirmation 'kkkkkkkkk'
      salt 'kkkkkkkkk'
      crypted_password 'kkkkkkkkk'
    end

    trait :no_api_keys do
      before(:create) do
        ::User.any_instance.stubs(:create_api_keys).returns(true)
      end
    end

    trait :auth_api do
      before(:create) do
        ::User.any_instance.stubs(:has_feature_flag?).with('auth_api').returns(true)
        ::User.any_instance.stubs(:has_feature_flag?).with('create_overviews').returns(true)
      end
    end

    factory :user_with_private_tables, traits: [:enabled, :private_tables]
    factory :admin, traits: [:admin]
    factory :valid_user, traits: [:valid]
    factory :locked_user, traits: [:valid, :locked]
    factory :no_api_keys_user, traits: [:valid, :no_api_keys]
    factory :auth_api_user, traits: [:valid, :auth_api]

    before(:create) do
      CartoDB::UserModule::DBService.any_instance.stubs(:enable_remote_db_user).returns(true)
    end
  end

  factory :carto_user, class: Carto::User do
    username { unique_name('user') }
    email { unique_email }

    password { email.split('@').first }
    password_confirmation { email.split('@').first }
    salt 'kkkkkkkkk'

    api_key '21ee521b8a107ea55d61fd7b485dd93d54c0b9d2'
    table_quota nil
    quota_in_bytes 5000000
    id { UUIDTools::UUID.timestamp_create.to_s }
    builder_enabled nil # Most tests still assume editor

    before(:create) do
      CartoDB::UserModule::DBService.any_instance.stubs(:enable_remote_db_user).returns(true)
    end

    after(:build) do |carto_user|
      carto_user.crypted_password = password_digest(carto_user.password, carto_user.salt)
    end

    after(:create) do |carto_user|
      ::User.where(id: carto_user.id).first.after_create
      CartoDB::UserModule::DBService.any_instance.unstub
    end

    trait :locked do
      state 'locked'
    end

    factory :carto_locked_user, traits: [:locked]
  end

end
