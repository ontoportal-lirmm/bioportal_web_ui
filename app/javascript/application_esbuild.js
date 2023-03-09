// Entry point for the build script in your package.json
import "./controllers";
import "./component_controllers";

import { Turbo } from "@hotwired/turbo-rails";
Turbo.session.drive = false;
