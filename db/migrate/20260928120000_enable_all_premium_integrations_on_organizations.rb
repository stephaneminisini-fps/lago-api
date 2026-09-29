# frozen_string_literal: true

class EnableAllPremiumIntegrationsOnOrganizations < ActiveRecord::Migration[8.0]
  PREMIUM_INTEGRATIONS = %w[
    beta_payment_authorization
    netsuite
    okta
    entra_id
    avalara
    xero
    progressive_billing
    lifetime_usage
    hubspot
    auto_dunning
    revenue_analytics
    salesforce
    api_permissions
    revenue_share
    remove_branding_watermark
    manual_payments
    from_email
    issue_receipts
    preview
    multi_entities_pro
    multi_entities_enterprise
    analytics_dashboards
    forecasted_usage
    projected_usage
    custom_roles
    events_targeting_wallets
    security_logs
    granular_lifetime_usage
    order_forms
    revenue_recognition
  ].freeze

  def up
    safety_assured do
      change_column_default :organizations, :premium_integrations, from: [], to: PREMIUM_INTEGRATIONS

      execute <<~SQL
        UPDATE organizations
        SET premium_integrations = ARRAY(
          SELECT DISTINCT unnest(premium_integrations || ARRAY[#{PREMIUM_INTEGRATIONS.map { |i| connection.quote(i) }.join(", ")}]::varchar[])
        )
      SQL
    end
  end

  def down
    safety_assured do
      change_column_default :organizations, :premium_integrations, from: PREMIUM_INTEGRATIONS, to: []
    end
  end
end
