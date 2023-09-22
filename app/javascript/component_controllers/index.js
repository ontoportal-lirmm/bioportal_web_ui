import {application} from "../controllers/application";

import TurboModalController from "../../components/turbo_modal_component/turbo_modal_component_controller"
import FileInputLoaderController
    from "../../components/input/file_input_component/file_input_loader_component_controller";

import Select_input_component_controller
    from "../../components/select_input_component/select_input_component_controller";
import Ontology_subscribe_button_component_controller
    from "../../components/ontology_subscribe_button_component/ontology_subscribe_button_component_controller";
import Search_input_component_controller
    from "../../components/search_input_component/search_input_component_controller";
import CircleProgressBarComponentController from "../../components/circle_progress_bar_component/circle_progress_bar_component_controller"
import Tabs_container_component_controller
    from "../../components/tabs_container_component/tabs_container_component_controller";

import alert_component_controller from "../../components/display/alert_component/alert_component_controller";
import Progress_pages_component_controller
    from "../../components/layout/progress_pages_component/progress_pages_component_controller";
import Reveal_component_controller from "../../components/layout/reveal_component/reveal_component_controller";


application.register("turbo-modal", TurboModalController)
application.register("file-input", FileInputLoaderController)
application.register("select-input", Select_input_component_controller)
application.register("subscribe-notes", Ontology_subscribe_button_component_controller)
application.register("search-input", Search_input_component_controller)
application.register("tabs-container", Tabs_container_component_controller)
application.register("circle-progress-bar", CircleProgressBarComponentController)
application.register("alert-component", alert_component_controller)
application.register("progress-pages", Progress_pages_component_controller)
application.register("reveal-component", Reveal_component_controller)
