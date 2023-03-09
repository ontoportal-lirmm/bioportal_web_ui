module Admin::LicensesHelper
  def license_notification(license)
    days = license.days_remaining

    if (days == 0)
      msg = (t(".license_expired") << " " << t(".license_contact")).html_safe
      notification = tag.div msg, class: "alert alert-danger mt-3", role: "alert"
    elsif license.is_trial?
      msg = (t(".license_trial", count: days) << " " << t(".license_obtain") << " " << t(".license_contact")).html_safe
      notification = tag.div msg, class: "alert alert-info mt-3", role: "alert"
    end

    notification ||= ""
  end
end
