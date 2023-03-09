import { application } from "../controllers/application";

import TurboModalController from "../../components/turbo_modal_component/turbo_modal_component_controller";
import FileInputLoaderController from "../../components/file_input_loader_component/file_input_loader_component_controller";

application.register("turbo-modal", TurboModalController);
application.register("file-input", FileInputLoaderController);
