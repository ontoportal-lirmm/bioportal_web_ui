class HistoryController < ApplicationController
  def remove # removes a 'history' tab
    remove_tab(undo_param(params[:ontology]))
    render :text => "success"
  end

  def update # updates the 'history' tab to point to the new node
    ontology = DataAccess.getOntology(params[:ontology])
    update_tab(ontology, params[:concept])
    render :text => "success"
  end
end
