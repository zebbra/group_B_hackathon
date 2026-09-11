defmodule MyAppWeb.Components.Core.Inputs.Textarea do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a textarea, optionally auto-resizing to fit its content.

  ## Examples

      <Core.Inputs.textarea field={@form[:bio]} label={~t"Bio"} />
      <Core.Inputs.textarea field={@form[:notes]} autoresize?={true} />

  """

  Inputs.common_attributes()

  attr :autoresize?, :boolean, default: false, doc: "grow the textarea to fit its content"

  attr :debounce, :any,
    default: nil,
    doc: "the phx-debounce value; derived from the field unless set (see validation_delayed?)"

  attr :rest, :global, include: ~w(autocomplete cols disabled form maxlength minlength placeholder
                readonly required rows)

  @spec textarea(map()) :: Rendered.t()
  def textarea(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> textarea()
  end

  def textarea(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <textarea
        id={@id}
        name={@name}
        phx-hook={@autoresize? && ".Autoresize"}
        phx-debounce={@debounce}
        class={[@class || "textarea w-full", @errors != [] && (@error_class || "textarea-error")]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    </Inputs.field>

    <script :type={ColocatedHook} name=".Autoresize" extension="ts">
      import { ViewHook } from "phoenix_live_view";

      export default class extends ViewHook<HTMLTextAreaElement> {
        declare resize: () => void;

        mounted() {
          this.resize = () => {
            this.el.style.height = "auto";
            this.el.style.height = `${this.el.scrollHeight + 2}px`;
          };
          this.el.addEventListener("input", this.resize);
          this.resize();
        }

        updated() {
          this.resize();
        }
      }
    </script>
    """
  end
end
