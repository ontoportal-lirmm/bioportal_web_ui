class NotesController < ApplicationController
  include TurboHelper
  layout 'ontology'
  NOTES_PROPOSAL_TYPES = {
    ProposalNewClass: "New Class Proposal",
    ProposalChangeHierarchy: "New Relationship Proposal",
    ProposalChangeProperty: "Change Property Value Proposal"
  }

  def show
    id = clean_note_id(params[:id])

    @note = LinkedData::Client::Models::Note.get(id, include_threads: true)
    @ontology = (@notes.explore.relatedOntology || []).first

    if request.xhr?
      render :partial => 'thread'
      return
    end
  end

  def new_comment
    render partial: 'new_comment', locals: { parent_id: params[:parent_id], type: params[:parent_type],
                                             user_id: session[:user].id, ontology_id: params[:ontology_id] }
  end

  def new_proposal
    types = NOTES_PROPOSAL_TYPES.map { |x, y| [y, x.to_s] }
    render partial: 'new_proposal', locals: { parent_id: params[:parent_id], type: params[:proposal_type],
                                              parent_type: params[:parent_type], user_id: session[:user].id,
                                              ontology_id: params[:ontology_id], types: types }
  end

  def new_reply
    render 'notes/reply/new', locals: { frame_id: "#{params[:parent_id]}_new_reply",
                                           parent_id: params[:parent_id], type: 'reply',
                                           user_id: session[:user].id }
  end

  def virtual_show
    note_id = params[:noteid]
    concept_id = params[:conceptid]
    ontology_acronym = params[:ontology]

    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ontology_acronym).first

    if note_id
      id = clean_note_id(note_id)
      @note = LinkedData::Client::Models::Note.get(id, include_threads: true)
      @note_decorator = NoteDecorator.new(@note, view_context)
    elsif concept_id
      @notes = @ontology.explore.single_class(concept_id).explore.notes
      @note_link = "/notes/virtual/#{@ontology.ontologyId}/?noteid="
      render :partial => 'list', :layout => 'ontology'
      return
    else
      @notes = @ontology.explore.notes
      @note_link = "/notes/virtual/#{@ontology.ontologyId}/?noteid="
      render :partial => 'list', :layout => 'ontology'
      return
    end

    if request.xhr?
      render partial: 'thread'
      return
    end

    render 'notes/show', layout: false
    end

  def create
    if params[:type].eql?("reply")
      note = LinkedData::Client::Models::Reply.new(values: note_params)
      new_note = note.save
      success_message = ''
      locals =  { note: new_note, parent_id: params[:parent]}
      partial = 'notes/reply/reply'
      container_id = "#{params[:parent]}_thread_replay_container"
      alerts_container_id = "#{params[:parent]}_reply"
    else
      if params[:proposal]
        cast_to_list = [:synonym, :definition, :newRelationshipType]
        cast_to_list.each do |property|
          params[:proposal][property] = params[:proposal][property].split(',') if params[:proposal][property]
        end
        params[:subject] = "#{NOTES_PROPOSAL_TYPES[params[:proposal][:type].to_sym]}: #{params[:proposal][:reasonForChange]}"
      end

      if params[:type].eql?("ontology")
        params[:relatedOntology] = [params.delete(:parent)]

      elsif params[:type].eql?("class")
        related_class = params.delete(:parent)
        ontology_id = params.delete(:ontology_id)
        params[:relatedClass] = [{ ontology: ontology_id, class: related_class }]
        params[:relatedOntology] = [ontology_id]
      end

      note = LinkedData::Client::Models::Note.new(values: note_params)
      new_note = note.save
      parent_type = params[:type].eql?("ontology") ? 'ontology' : 'class'
      ontology_acronym = new_note.relatedOntology.first.split('/').last
      success_message = 'New comment added successfully'
      locals =  { note: new_note, ontology_acronym: ontology_acronym, parent_type: parent_type }
      partial = 'notes/note_line'
      container_id = "#{parent_type}_notes_table_content"
      alerts_container_id = nil
    end


    if new_note.errors
      render_turbo_stream alert_error(id: alerts_container_id) { response_errors(new_note).to_s }
    else
      streams = [prepend(container_id, partial: partial, locals: locals)]
      streams.unshift(alert_success { success_message }) unless params[:type].eql?("reply")

      render_turbo_stream *streams
    end
  end

  def destroy
    note_id = params[:noteid]
    note = LinkedData::Client::Models::Note.get(note_id)
    response = {}
    if note
      note.delete

      if note.errors
        response[:errors] = note.errors
      else
        response[:success] = "Note #{note_id}  was deleted successfully"
      end
    else
      response[:errors] = "Note #{note_id}  was not found in the system"
    end
    parent_type = params[:parent_type]
    alerts_container_id = "notes_#{parent_type}_list_table_alerts"
    if response[:errors]
      render_turbo_stream alert_error(id: alerts_container_id) { response[:errors].join(',').to_s }
    else
      render_turbo_stream(alert_success(id: alerts_container_id) { response[:success] }, remove("#{note_id}_tr_#{parent_type}"))
    end

  end

  def archive
    ontology = DataAccess.getLatestOntology(params[:ontology_virtual_id])

    unless ontology.admin?(session[:user])
      render :json => nil.to_json, :status => 500
      return
    end

    @archive = DataAccess.archiveNote(params)

    unless @archive.nil?
      render :json => @archive.to_json
    end
  end

  def show_concept_list
    params[:p] = "classes"
    params[:t] = "notes"
    redirect_new_api
  end

  private

  def note_params
    p = params.permit(:parent, :type, :subject, :body, :creator, { relatedClass:[:class, :ontology] }, { relatedOntology:[] },
                      proposal: [:type, :reasonForChange, :classId, :label, { synonym:[] }, { definition:[] },
                                 :parent, :newTarget, :oldTarget, { newRelationshipType:[] }, :propertyId,
                                 :newValue, :oldValue])
    p.to_h
  end

  # Fix noteid parameters with bad prefixes (some application servers, e.g., Apache, NGINX, mangle encoded slashes).
  def clean_note_id(id)
    id = id.match(/\Ahttp:\/\w/) ? id.sub('http:/', 'http://') : id
    CGI.unescape(id)
  end

end
