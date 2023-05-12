import {application} from "../controllers/application";

import TurboModalController from "../../components/turbo_modal_component/turbo_modal_component_controller"
import FileInputLoaderController
    from "../../components/file_input_loader_component/file_input_loader_component_controller";

import Select_input_component_controller
    from "../../components/select_input_component/select_input_component_controller";
import Metadata_selector_component_controller
    from "../../components/metadata_selector_component/metadata_selector_component_controller";
import Ontology_subscribe_button_component_controller
    from "../../components/ontology_subscribe_button_component/ontology_subscribe_button_component_controller";
import Toggle_input_component_controller
    from "../../components/toggle_input_component/toggle_input_component_controller";

application.register("turbo-modal", TurboModalController)
application.register("file-input", FileInputLoaderController)
application.register("select-input", Select_input_component_controller)
application.register("metadata-select", Metadata_selector_component_controller)
application.register("subscribe-notes", Ontology_subscribe_button_component_controller)
application.register("toggle-input", Toggle_input_component_controller)
