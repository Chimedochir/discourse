import Component from "@glimmer/component";
import { isTesting } from "discourse-common/config/environment";

export default class DFloatPortal extends Component {
  <template>
    {{#if this.inline}}
      {{yield}}
    {{else}}
      {{#in-element @portalOutletElement}}
        {{yield}}
      {{/in-element}}
    {{/if}}
  </template>

  get inline() {
    return this.args.inline ?? isTesting();
  }
}
