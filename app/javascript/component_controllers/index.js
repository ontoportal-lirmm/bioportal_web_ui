import {application} from "../controllers/application";

import TurboModalController from "../../components/turbo_modal_component/turbo_modal_component_controller"
import FileInputLoaderController
    from "../../components/form/file_input_component/file_input_loader_component_controller";

import Select_input_component_controller
    from "../../components/select_input_component/select_input_component_controller";
import Metadata_selector_component_controller
    from "../../components/metadata_selector_component/metadata_selector_component_controller";
import Ontology_subscribe_button_component_controller
    from "../../components/ontology_subscribe_button_component/ontology_subscribe_button_component_controller";
import Search_input_component_controller
    from "../../components/search_input_component/search_input_component_controller";

import Tabs_container_component_controller
    from "../../components/tabs_container_component/tabs_container_component_controller";

application.register("turbo-modal", TurboModalController)
application.register("file-input", FileInputLoaderController)
application.register("select-input", Select_input_component_controller)
application.register("metadata-select", Metadata_selector_component_controller)
application.register("subscribe-notes", Ontology_subscribe_button_component_controller)
application.register("search-input", Search_input_component_controller)
application.register("tabs-container", Tabs_container_component_controller)
