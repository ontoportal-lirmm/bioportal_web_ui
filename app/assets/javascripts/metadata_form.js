$(document).ready(function(){
  //###### ADD CREATOR ######
  $("#button-add-creator").click(function(e) {
    addCreator();
    e.preventDefault();
  });

  $('#button-add-title').click(function(e) {   
    addTitle();
    e.preventDefault();
  });

  updateIdentifierType();
  $("#submission_identifierType").change(function(e){
    updateIdentifierType();
  });

  $("#submission_publicationYear").attr({
    "max" : (new Date()).getFullYear(),
    "min" : 1980
  });

  checkEnablingStatus_RemoveCreatorButton();
  checkEnablingStatus_RemoveTitleButton();

  // add events related to path management
  $("#submission_filePath").change(event => {
    let pathname = "";
    if (event.target.files.length > 0) {
      pathname = event.target.files[0].name;
    }
    $("#submission_filePathVisualization").text(pathname);
  });
});


/////////////// CREATORS /////////////////////
function addCreator(creatorObj) {

  let html = `
  <div class="col-sm-12">
  <!--RADIO BUTTON TO CHOOSE BETWEEN PARSONAL or ORGANIZATIONAL CREATOR-->
  <div class="row creatorType">
    <div class="col-sm-4 radio-xs">
      <label class="lbl-creatorType">
        <input type="radio" name="submission[creators[$1][nameType]]" id="radio-creatorType-Personal-$1" value="Personal" onclick="changeCreatorType($1, 'Personal')">
        Person
      </label>
    </div>
    <div class="col-sm-4 radio-xs">
      <label class="lbl-creatorType">
        <input type="radio" name="submission[creators[$1][nameType]]" id="radio-creatorType-Organizational-$1" value="Organizational" onclick="changeCreatorType($1, 'Organizational')">
        Organization
      </label>
    </div>

    <!-- BUTTON REMOVE CREATOR ROW -->
    <div class="col-sm-offset-1 col-sm-3">                  
      <button type="button" onclick="removeCreator('creator-$1')" class="btn btn-primary btn-sm"  access="false" id="button-remove-creator-$1">
        Remove This Creator <span class="fas fa-trash-alt"></span></button>
    </div>
  </div>

  <!-- CREATORS IDENTIFIER -->
  <div id="creatorIdentifiers" class="sub-section">                    
    <div id="creatorIdentifiers-$1">
      <!-- here will be added the creator creatorIdentifiers -->
      
    </div>
    <div class="row row-creatorIdentifier-buttons">
      <div class="col-sm-11">
        <button type="button" class="col-md-4 btn btn-primary" access="false" id="button-add-creatorIdentifier" onclick="addCreatorIdentifier($1)">
          <span class="fas fa-plus" aria-hidden="true"></span> Add Creator Identifier</button>
      </div>
    </div>
  </div>                  
    
  <!-- PERSON -->
  <div class="row nested-row-values" id="div-creator-personal-field-$1">
    <div class="col-sm-2 ">
      <label class="float-right col-form-label" for="submission_creators[$1][givenName]">First Name:<span class="asterik">*</span></label></div>
    <div class="col-sm-4">
      <input class="form-control input-sm w100perc" type="text" name="submission[creators[$1][givenName]]" id="submission_creators[$1][givenName]" oninput="updateCreatorName($1)" required="required"/></div> 
    
    <div class="col-sm-2">
      <label class="float-right col-form-label" for="submission_creators[$1][familyName]">Surname:<span class="asterik">*</span></label></div>
    <div class="col-sm-4">
      <input class="form-control input-sm w100perc" type="text" name="submission[creators[$1][familyName]]" id="submission_creators[$1][familyName]" oninput="updateCreatorName($1)" required="required"/></div> 
  </div>

  <!-- ORGANIZATION -->
  <div class="row nested-row-values">
    <div class="col-sm-2 ">
      <label class="float-right col-form-label" for="submission_creators[$1][creatorName]">Name:<span class="asterik">*</span></label></div>
    <div class="col-sm-10">
      <input class="form-control input-sm w100perc" type="text" name="submission[creators[$1][creatorName]]" id="submission_creators[$1][creatorName]" readonly required="required"/></div>
  </div>

  <!-- AFFILIATION -->
  <div id="affiliations" class="sub-section">
    
    <div id="creatorAffiliations-$1">
      
      <!-- here will be added the creator affiliations -->
      
    </div>

    <div class="row row-creatorAffiliation-buttons">
      <div class="col-sm-11">
        <button type="button" class="col-md-4 btn btn-primary" id="button-add-creatorAffiliation" onclick="addCreatorAffiliation($1)">
          <span class="fas fa-plus" aria-hidden="true"></span> Add Affiliation</button>
      </div>
    </div>
  </div>
</div>`

  const $creators = $("#creators");
  let index = $creators.children().length;

  html = html.replace(/\$1/g, index);    

  let div = $('<div/>', { class:"row row-creator", id:"creator-" + index });
  div.append(html);
  $creators.append(div);
  
  if(creatorObj)
    setCreatorObject(index, creatorObj);

  checkEnablingStatus_RemoveCreatorButton();
}

/**
 * Remove a contact by row id
 * @param {*} id 
 */
function removeCreator(id){
  removeElementById(id);
  indexes = getIndexesFromElementId(id);
  reindexCreator()
  checkEnablingStatus_RemoveCreatorButton();
}

function checkEnablingStatus_RemoveCreatorButton() {
  if($("#creators").children().length == 1) {
    hideElementById('button-remove-creator-0');
  } else {
    showElementById('button-remove-creator-0');
  }
}



/**
 * Re-index the contact
 */
function reindexCreator(){
  newCreatorArray = [];
  //PHASE 1: for each contact :
  //  a) save its values into a creator object
  //  b) store the creator object into an array of creators
  //  c) remove the creatorI row from the html page
  $("#creators").children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[0];
    creatorObj = getCreatorObject(index);
    newCreatorArray.push(creatorObj);
    
    v.remove();
  })
  //PHASE 2: for each creatorIdentifier saved into the array, create a new html with the right index
  newCreatorArray.forEach((v) => {
    addCreator(v);
  })
}

function getCreatorObject(creatorIndex){
  creatorObj = {};

  nameType_selector = 'submission[creators[' + creatorIndex + '][nameType]]';
  givenName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][givenName]');
  familyName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][familyName]');
  creatorName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorName]');
      
  creatorObj.nameType = $('input[name="' + nameType_selector + '"]:checked').val();
  creatorObj.givenName = $('#' + givenName_selector).val();  
  creatorObj.familyName = $('#' + familyName_selector).val();   
  creatorObj.creatorName = $('#' + creatorName_selector).val();

  creatorIdentifierArray = []
  $("#creatorIdentifiers-" + creatorIndex).children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[1];    
    creatorIdentifierObj = getCreatorIdentifierObj(creatorIndex, index)  
    creatorIdentifierArray.push(creatorIdentifierObj);    
  })
  creatorObj.creatorIdentifiers = creatorIdentifierArray;

  creatorAffiliationArray = []
  $("#creatorAffiliations-" + creatorIndex).children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[1];    
    creatorAffiliationObj = getCreatorAffiliationObj(creatorIndex, index);
    creatorAffiliationArray.push(creatorAffiliationObj);   
  })
  creatorObj.creatorAffiliations = creatorAffiliationArray;

  return creatorObj;

}


function setCreatorObject(creatorIndex ,creatorObj){
  if(creatorObj) {  
    nameType_selector = $.escapeSelector('radio-creatorType-' + creatorObj.nameType + '-' + creatorIndex);
    givenName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][givenName]');
    familyName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][familyName]');
    creatorName_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorName]');      


    $('#' + nameType_selector).click();
    $('#' + givenName_selector).val(creatorObj.givenName);  
    $('#' + familyName_selector).val(creatorObj.familyName);   
    $('#' + creatorName_selector).val(creatorObj.creatorName);


    if(creatorObj.creatorIdentifiers){
      $("#creatorIdentifiers-" + creatorIndex).children().remove();
      creatorObj.creatorIdentifiers.forEach((obj,i) => {
        addCreatorIdentifier(creatorIndex, obj);
      });
    }

    if(creatorObj.creatorAffiliations){
      $("#creatorAffiliations-" + creatorIndex).children().remove();
      creatorObj.creatorAffiliations.forEach((obj,i) => {
        addCreatorAffiliation(creatorIndex, obj);
      });
    }

  }
}


function changeCreatorType(index, value) {
  if(typeof value === 'undefined'){
    value = $('input[name="submission[creators[' + index + '][nameType]]"]:checked').val();
  }
  if(value === 'Personal'){
    showPersonalCreator(index);
  } else {
    showOrganizationalCreator(index);
  } 
}

function showPersonalCreator(index){
  resetCreatorFields(index);
  selector = $.escapeSelector('submission_creators[' + index + '][creatorName]');
  $('#' + selector).prop("readonly", true);
  selectorGivenName = $.escapeSelector('submission_creators[' + index + '][givenName]');
  selectorFamilyName = $.escapeSelector('submission_creators[' + index + '][familyName]');
  $('#' + selectorGivenName).prop('required', true);
  $('#' + selectorFamilyName).prop('required', true);
  $('#div-creator-personal-field-' + index).show();
}

function showOrganizationalCreator(index){
  resetCreatorFields(index);
  selector = $.escapeSelector('submission_creators[' + index + '][creatorName]');
  $('#' + selector).prop("readonly", false);
  $('#div-creator-personal-field-' + index).hide();
  selectorGivenName = $.escapeSelector('submission_creators[' + index + '][givenName]');
  selectorFamilyName = $.escapeSelector('submission_creators[' + index + '][familyName]');
  $('#' + selectorGivenName).removeAttr('required');
  $('#' + selectorFamilyName).removeAttr('required');
}

function updateCreatorName(index) {
  selectorCreatorName = $.escapeSelector('submission_creators[' + index + '][creatorName]');
  selectorGivenName = $.escapeSelector('submission_creators[' + index + '][givenName]');
  selectorFamilyName = $.escapeSelector('submission_creators[' + index + '][familyName]');
  newCratorNameValue = $('#' + selectorGivenName).val() + " " + $('#' + selectorFamilyName).val();
  $('#' + selectorCreatorName).val(newCratorNameValue);
}

function resetCreatorFields(index) {  
  selectorGivenName = $.escapeSelector('submission_creators[' + index + '][givenName]');
  selectorFamilyName = $.escapeSelector('submission_creators[' + index + '][familyName]');
  selectorCreatorName = $.escapeSelector('submission_creators[' + index + '][creatorName]');
  $('#' + selectorGivenName).val("");
  $('#' + selectorFamilyName).val("");
  $('#' + selectorCreatorName).val("");
}

/////////////// CREATOR IDENTIFIER /////////////////////

function addCreatorIdentifier(creatorIndex, creatorIdentifierObj) {
  html = `
    <div class="col-sm-11">
      <div class="row nested-row-values">
        <div class="col-sm-2">
          <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifierScheme]">Scheme:<span class="asterik">*</span></label></div>
        <div class="col-sm-4">
          <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifierScheme]]" id="submission_creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifierScheme]" required="required"/>
          <small class="form-text text-muted">Ex.: ISNI, ORCID</small>
        </div> 
        <div class="col-sm-2">
          <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][creatorIdentifiers][$1][schemeURI]">Scheme URI:<span class="asterik">*</span></label></div>
        <div class="col-sm-4">
          <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][creatorIdentifiers][$1][schemeURI]]" id="submission_creators[${creatorIndex}][creatorIdentifiers][$1][schemeURI]" required="required"/>
          <small class="form-text text-muted">Ex.: http://isni.org/isni/, http://orcid.org/</small>
        </div> 
      </div>
      <div class="row nested-row-values">
        <div class="col-sm-2">
          <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifier]">Name Identifier:<span class="asterik">*</span></label></div>
        <div class="col-sm-10">
          <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifier]]" id="submission_creators[${creatorIndex}][creatorIdentifiers][$1][nameIdentifier]" required="required"/>
          <small class="form-text text-muted">Example for ISNI: 0000000134596520 or for ORCID: 0000-0001-5393-1421</small>
        </div>
      </div>
    </div>
    <!-- BUTTON REMOVE CREATOR IDENTIFIER ROW -->
    <div class="col-sm-1">
      <button type="button" onclick="removeCreatorIdentifier('creatorIdentifier-${creatorIndex}_$1')" class="btn btn-primary btn-remove-row"  access="false" id="button-remove-creatorIdentifier-${creatorIndex}_$1">
      <span class="fas fa-trash-alt"></span></button>
    </div>`;
 
 
  index = $("#creatorIdentifiers-" + creatorIndex).children().length;  
  html = html.replace(/\$1/g, index);

  let div = $('<div/>', { class:"row-creatorIdentifier", id:"creatorIdentifier-" + creatorIndex + "_" + index });
  div.append(html);
     
  $("#creatorIdentifiers-" + creatorIndex).append(div)

  if(creatorIdentifierObj) {
    setCreatorIdentifier(creatorIndex, index, creatorIdentifierObj)
  }

}

/**
 * Remove a contact by row id
 * @param {*} id 
 */
function removeCreatorIdentifier(id){
  removeElementById(id);
  indexes = getIndexesFromElementId(id);
  reindexCreatorIdentifierByCreatorIndex(indexes[0]);
}


/**
 * Re-index the contact
 */
function reindexCreatorIdentifierByCreatorIndex(creatorIndex){
  newCreatorIdentifierArray = [];
  //PHASE 1: for each contact :
  //  a) save its values into a creatorIdentifier object
  //  b) store the creatorIdentifier object into an array of creatorIdentifiers
  //  c) remove the creatorIdentifier row from the html page
  $("#creatorIdentifiers-" + creatorIndex).children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[1];    
    creatorIdentifierObj = getCreatorIdentifierObj(creatorIndex, index)
    newCreatorIdentifierArray.push(creatorIdentifierObj);
    v.remove();
  })
  //PHASE 2: for each creatorIdentifier saved into the array, create a new html with the right index
  newCreatorIdentifierArray.forEach((v) => {
    addCreatorIdentifier(creatorIndex, v);
  })
}

/**
 * Get an object containing all values of a creator Identifier
 * @param {*} creatorIndex - index of the creator section
 * @param {*} creatorIdentifierIndex - index of the indentifier section into the creator section specified by creatorIndex
 */
function getCreatorIdentifierObj(creatorIndex, creatorIdentifierIndex) {
  creatorIdentifierObj = {};

  nameIdentifierScheme_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][nameIdentifierScheme]');
  schemeURI_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][schemeURI]');
  nameIdentifier_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][nameIdentifier]');
  
  creatorIdentifierObj.nameIdentifierScheme = $('#' + nameIdentifierScheme_selector).val();
  creatorIdentifierObj.schemeURI = $('#' + schemeURI_selector).val();  
  creatorIdentifierObj.nameIdentifier = $('#' + nameIdentifier_selector).val(); 
  
  return creatorIdentifierObj;
}


function setCreatorIdentifier(creatorIndex, creatorIdentifierIndex, creatorIdentifierObj) {
  
  nameIdentifierScheme_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][nameIdentifierScheme]');
  schemeURI_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][schemeURI]');
  nameIdentifier_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][creatorIdentifiers][' + creatorIdentifierIndex + '][nameIdentifier]');
  $('#' + nameIdentifierScheme_selector).val(creatorIdentifierObj.nameIdentifierScheme);
  $('#' + schemeURI_selector).val(creatorIdentifierObj.schemeURI);  
  $('#' + nameIdentifier_selector).val(creatorIdentifierObj.nameIdentifier);   
}


/////////////// CREATOR AFFILIATION /////////////////////

function addCreatorAffiliation(creatorIndex, creatorAffiliationObj) {

  html = `
  <div class="col-sm-11">
    <div class="row nested-row-values">
      <div class="col-sm-2">
        <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][affiliations][$1][affiliationIdentifierScheme]">Scheme:<span class="asterik">*</span></label></div>
      <div class="col-sm-4">
        <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][affiliations][$1][affiliationIdentifierScheme]]" id="submission_creators[${creatorIndex}][affiliations][$1][affiliationIdentifierScheme]" required="required"/>
        <small class="form-text text-muted">Ex. ROR</small>
      </div> 

      <div class="col-sm-2">
        <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][affiliations][$1][affiliationIdentifier]">Affiliation Ident. URI:<span class="asterik">*</span></label></div>
      <div class="col-sm-4">
        <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][affiliations][$1][affiliationIdentifier]]" id="submission_creators[${creatorIndex}][affiliations][$1][affiliationIdentifier]" required="required"/>
        <small class="form-text text-muted">Ex. https://ror.org/04wxnsj81</small>
      </div> 
    </div>
    <div class="row nested-row-values">
      <div class="col-sm-2">
        <label class="float-right lb-sm col-form-label" for="submission_creators[${creatorIndex}][affiliations][$1][affiliation]">Affiliation Name:<span class="asterik">*</span></label></div>
      <div class="col-sm-10">
        <input class="form-control input-sm w100perc" type="text" name="submission[creators[${creatorIndex}][affiliations][$1][affiliation]]" id="submission_creators[${creatorIndex}][affiliations][$1][affiliation]" required="required"/>
        <small class="form-text text-muted">Enter the name of the formal institution to which the creator belongs, e.g. LifeWatch ERIC, DataCite, etc.</small>
      </div>
    </div>
  </div>
  <!-- BUTTON REMOVE CREATOR AFFILIATION ROW -->
  <div class="col-sm-1">
    <button type="button" onclick="removeCreatorAffiliation('creatorAffiliation-${creatorIndex}_$1')" class="btn btn-primary btn-remove-row"  access="false" id="button-remove-creatorAffiliation-${creatorIndex}_$1">
      <span class="fas fa-trash-alt"></span></button>
  </div>`;
 
 
  index = $("#creatorAffiliations-" + creatorIndex).children().length;  
  html = html.replace(/\$1/g, index);

  let div = $('<div/>', { class:"row-creatorAffiliation", id:"creatorAffiliation-" + creatorIndex + "_" + index });
  div.append(html);
   
  $("#creatorAffiliations-" + creatorIndex).append(div) 

  if(creatorAffiliationObj){    
    setCreatorAffiliation(creatorIndex, index, creatorAffiliationObj)
  }
}

/**
 * Remove a contact by row id
 * @param {*} id 
 */
function removeCreatorAffiliation(id){
  removeElementById(id);
  indexes = getIndexesFromElementId(id);
  reindexCreatorAffiliationByCreatorIndex(indexes[0]);
}


/**
 * Re-index the contact
 */
function reindexCreatorAffiliationByCreatorIndex(creatorIndex){
  newCreatorAffiliationArray = [];
  //PHASE 1: for each contact :
  //  a) save its values into a creatorAffiliation object
  //  b) store the creatorAffiliation object into an array of creatorAffiliations
  //  c) remove the creatorAffiliation row from the html page
  $("#creatorAffiliations-" + creatorIndex).children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[1];    
    creatorAffiliationObj = getCreatorAffiliationObj(creatorIndex, index);
    newCreatorAffiliationArray.push(creatorAffiliationObj);
    v.remove();
  })
  //PHASE 2: for each creatorAffiliation saved into the array, create a new html with the right index
  newCreatorAffiliationArray.forEach((v) => {    
    addCreatorAffiliation(creatorIndex, v);
  })
}


function getCreatorAffiliationObj(creatorIndex, creatorAffiliationIndex){
  creatorAffiliationObj = {};

  affiliationIdentifierScheme_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliationIdentifierScheme]');
  affiliationIdentifier_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliationIdentifier]');
  affiliation_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliation]');


  creatorAffiliationObj.affiliationIdentifierScheme = $('#' + affiliationIdentifierScheme_selector).val();
  creatorAffiliationObj.affiliationIdentifier = $('#' + affiliationIdentifier_selector).val();  
  creatorAffiliationObj.affiliation = $('#' + affiliation_selector).val();

  return creatorAffiliationObj;
}


function setCreatorAffiliation(creatorIndex, creatorAffiliationIndex, creatorAffiliationObj) { 
  affiliationIdentifierScheme_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliationIdentifierScheme]');
  affiliationIdentifier_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliationIdentifier]');
  affiliation_selector = $.escapeSelector('submission_creators[' + creatorIndex + '][affiliations][' + creatorAffiliationIndex + '][affiliation]');
  
  $('#' + affiliationIdentifierScheme_selector).val(creatorAffiliationObj.affiliationIdentifierScheme);
  $('#' + affiliationIdentifier_selector).val(creatorAffiliationObj.affiliationIdentifier);  
  $('#' + affiliation_selector).val(creatorAffiliationObj.affiliation);
}

/////////////// IDENTIFIER /////////////////////
function updateIdentifierType() {
  let value = $("#submission_identifierType").val();
  disableById('submission_identifier');
  hideElementById('div-cb-require-doi');
  hideElementById('button-load-by-doi');
  $("#doi_request").prop( "checked", false );
  if (typeof value !== 'undefined'){
    switch (value.toLowerCase()) {
      case 'none':      
        showElementById('div-cb-require-doi');
        $("#submission_identifier").val('')
        break;
      case 'doi':      
        enableById('submission_identifier');
        showElementById('button-load-by-doi')
        break;
      case 'other':
        enableById('submission_identifier');
        break;
    }
  }
}


/////////////// TITLES /////////////////////
function addTitle(titleObj) {
  value_title = "";
  value_lang = "";
  value_titleType = "";
 
  if(titleObj){
    value_title = titleObj.title ? 'value="' + titleObj.title + '"' : '';
    value_lang = titleObj.lang ? titleObj.lang: '';
    value_titleType = titleObj.titleType ? titleObj.titleType: '';    
  }

  html = `
    <div class="col-sm-11">
      <!-- row for text title -->
      <div class="row nested-row-values">
        <div class="col-sm-2">
          <label class="float-right col-form-label" for="submission_titles[$1][title]">Title:<span class="asterik">*</span></label></div>
        <div class="col-sm-10">
          <input class="form-control input-sm w100perc" type="text" name="submission[titles[$1][title]]" id="submission_titles[$1][title]" ${value_title} required="required"/></div>
      </div>
      <!-- row for text lang and type -->
      <div class="row nested-row-values">
        <div class="col-sm-2">
          <label class="float-right col-form-label" for="submission_titles[$1][lang]">Language:<span class="asterik">*</span></label></div>
        <div class="col-sm-4">
          <select class="form-control input-sm w100perc" name="submission[titles[$1][lang]]" id="submission_titles[$1][lang]" ${value_lang}>
            <option value="en-EN">English</option>
            <option value="it-IT">Italian</option>
            <option value="fr-FR">French</option>
            <option value="de-DE">German</option>
            <option value="es-ES">Spanish</option>                  
          </select>     
        </div>
        <div class="col-sm-1">
          <label class="float-right col-form-label" for="submission_titles[$1][titleType]">Type:</label></div>
        <div class="col-sm-5">
          <select class="form-control input-sm w100perc" name="submission[titles[$1][titleType]]" id="submission_titles[$1][titleType]" ${value_titleType}>
            <option value="AlternativeTitle">Alternative Title</option>
            <option value="Subtitle">Subtitle</option>
            <option value="TranslatedTitle">Translated Title</option>
            <option value="Other">Other</option>                              
          </select>     
        </div>
      </div>
    </div>
    <div class="col-sm-1 div-btn-remove">                  
      <button type="button" onclick="removeTitle('title-$1')" class="btn btn-primary btn-remove-title"  access="false" id="button-remove-title-$1">
      <span class="fas fa-trash-alt"></span></button>
    </div>`


  index = $("#titles").children().length;  

  html = html.replace(/\$1/g, index);

  let div = $('<div/>', { class:"row row-title", id:"title-" + index });
  div.append(html);
  
  lang_selector = $.escapeSelector('submission_titles[' + index + '][lang]');
  titleType_selector = $.escapeSelector('submission_titles[' + index + '][titleType]');  
  
  $("#titles").append(div)

  if(value_lang!== "") div.find('#' + lang_selector).val(value_lang);
  if(value_titleType!== "") div.find('#' + titleType_selector).val(value_titleType);

  checkEnablingStatus_RemoveTitleButton();
}

/**
 * Remove a contact by row id
 * @param {*} id 
 */
function removeTitle(id){
  removeElementById(id);
  reindexTitle();
  checkEnablingStatus_RemoveTitleButton();
}

/**
 * Re-index the contact
 */
function reindexTitle(){
  newTitleArray = [];
  //PHASE 1: for each contact :
  //  a) save its values into a title object
  //  b) store the title object into an array of titles
  //  c) remove the titleI row from the html page
  $("#titles").children().each((k,v) => {    
    id = v.id;
    index = getIndexesFromElementId(id)[0];
    titleObj = {};

    title_selector = $.escapeSelector('submission_titles[' + index + '][title]');
    lang_selector = $.escapeSelector('submission_titles[' + index + '][lang]');
    titleType_selector = $.escapeSelector('submission_titles[' + index + '][titleType]');
    
       
    titleObj.title = $('#' + title_selector).val();
    titleObj.lang = $('#' + lang_selector).val();  
    titleObj.titleType = $('#' + titleType_selector).val();   
    
    newTitleArray.push(titleObj);
    v.remove();
  })
  //PHASE 2: for each titleIdentifier saved into the array, create a new html with the right index
  newTitleArray.forEach((v) => {    
    addTitle(v);
  })
}


function checkEnablingStatus_RemoveTitleButton() {
  if($("#titles").children().length == 1) {
    hideElementById('button-remove-title-0');
  } else {
    showElementById('button-remove-title-0');
  }
}



///////////// UTILS ////////////

/**
 * Remove an element by id
 * @param {Remove } id 
 */
function removeElementById(id) {
  $("#" +  id).remove();
}

/**
 * disable the element by Id and all its children
 * @param {*} id 
 */
function disableById(id){
  let elem =  $("#" + id);
  elem.prop("disabled", true); //.addClass('disabled');
  if(elem.children().length) {
    elem.children().prop("disabled", true);
  }
}

function enableById(id){
  let elem =  $("#" + id);
  elem.prop("disabled", false);
  if(elem.children().length) {
    elem.children().prop("disabled", false);
  }
}

function hideElementById(id){
  $("#" + id).hide();
}

function showElementById(id){
  $("#" + id).show();
}

/**
 * Retreive the indexes from element id.
 * Examples:
 *  > id= "myId-1_2" returns array ["1", "2"]
 *  > id= "myId-1" returns array ["1"]
 * @param {} id
 * @returns {Array}
 */
function getIndexesFromElementId(id) {
  return id.split("-")[1].split("_")
}

$.escapeSelector = function (txt) {
  return txt.replace(
      /([$%&()*+,./:;<=>?@\[\\\]^\{|}~])/g,
      '\\$1'
  );
};