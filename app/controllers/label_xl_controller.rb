class LabelXlController < ApplicationController
  include LabelXlHelper, UrlsHelper

  def show
    @label_xl = get_request_label_xl
  end

  def show_label
    label_xl = get_request_label_xl
    label_xl_label = label_xl ? label_xl['literalForm'] : nil
    label_xl_label = params[:id] if label_xl_label.nil? || label_xl_label.empty?
    label = helpers.main_language_label(label_xl_label)
    link = "/ajax/label_xl/?id=#{escape(params[:id])}&ontology=#{params[:ontology_id]}&cls_id=#{escape(params[:cls_id])}"
    render(inline: helpers.ajax_link_chip(params[:id], label, link, open_in_modal: true, external: label_xl.blank?), layout: false)
  end

  private

  def get_request_label_xl
    params[:id] = params[:id] ? params[:id] : params[:label_xl_id]
    params[:ontology_id] = params[:ontology_id] ? params[:ontology_id] : params[:ontology]
    if params[:id].nil? || params[:id].empty?
      render text: t('label_xl.error_valid_label_xl')
      return
    end
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params[:ontology_id]).first
    @ontology_acronym = @ontology.acronym
    get_label_xl(@ontology, params[:id])
  end

end
