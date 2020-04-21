defmodule Linex do
  @moduledoc """
  This is a flex message template module
  included in the LINE messaging API.

  You can freely customize
  the layout using basic knowledge of CSS Flexible Box.

  Flex messages consist of the following
  three layers of data structure.

  structure: container
  Container is the top level structure of Flex Message

  structure: block
  Blocks are the structures that make up a bubble

  structure: component
  Components are the elements that make up a block

  A flex message consists of the above data structure
  and the flex object that has them as children.
  """

  @doc """
  Create a new maintained bubble container
  """

  def new(blocks, alt, {:bubble, opt}) do
    bubble(blocks, opt)
    |> flex(alt)
    |> map_filter()
  end

  @doc """
  Flex object
  with three layers of data structure as child
  """

  def flex(container, alt) do
    %{
      type: "flex",
      altText: alt,
      contents: container
    }
  end

  # --- structure: container --- #

  @doc """
  container: bubble
  A container that makes up one message bubble
  """

  def bubble(blocks, opt) do
    %{
      type: "bubble",
      header: blocks[:header],
      hero: blocks[:blocks],
      body: blocks[:body],
      footer: blocks[:footer],
      styles: %{
        header: opt[:header],
        hero: opt[:hero],
        body: opt[:body],
        footer: opt[:footer]
      }
    }
  end

  # --- structure: block --- #

  ## Note: Block depends on bubble container

  # --- structure: component --- #

  @doc """
  component: box
  The component that defines the layout of the component
  """

  def box(contents, {:vertical, opt}) do
    contents |> template_box("vertical", opt)
  end

  def box(contents, {:horizontal, opt}) do
    contents |> template_box("horizontal", opt)
  end

  # The underlying function

  defp template_box(contents, layout, opt) do
    %{
      type: "box",
      layout: layout,
      contents: guarantee_list(contents),
      action: opt[:action]
    }
    |> Map.merge(box_opt opt)
  end

  @doc """
  component: image
  The component that draws the image
  """

  def image(url, opt) do
    %{
      type: "image",
      url: url,
      action: opt[:action]
    }
    |> Map.merge(image_opt opt)
  end

  @doc """
  component: text
  The component that draws a string of one line
  """

  def text(contents, {:span, opt}) do
    template_text(opt)
    |> Map.put(:contents, contents)
  end

  def text(text, opt) do
    template_text(opt)
    |> Map.put(:text, text)
  end

  # The underlying function

  defp template_text(opt) do
    %{type: "text", action: opt[:action]}
    |> Map.merge(text_opt opt)
  end

  @doc """
  component: span
  The component that draws multiple character strings
  with different designs in one line
  """

  def span(text, opt) do
    %{type: "span", text: text}
    |> Map.merge(span_opt opt)
  end

  # --- options --- #

  defp box_opt(opt) do
    %{
      spacing: opt[:spacing],
      width: opt[:width],
      height: opt[:height],
      borderWidth: opt[:border_width],
      borderColor: opt[:border_color],
      cornerRadius: opt[:corner_radius]
    }
    |> Map.merge(base_opt opt, except: [:gravity, :size, :align])
    |> Map.merge(offset_opt opt)
    |> Map.merge(padding_opt opt)
  end

  defp image_opt(opt) do
    %{
      aspectRatio: opt[:aspect_ratio],
      aspectMode: opt[:aspect_mode]
    }
    |> Map.merge(base_opt opt)
    |> Map.merge(offset_opt opt)
  end

  defp template_text_opt(opt) do
    %{
      weight: opt[:weight],
      color: opt[:color],
      style: opt[:style],
      decoration: opt[:decoration]
    }
  end

  defp text_opt(opt) do
    %{
      wrap: opt[:wrap],
      maxLines: opt[:max_lines]
    }
    |> Map.merge(template_text_opt opt)
    |> Map.merge(base_opt opt, except: [:backgroundColor])
    |> Map.merge(offset_opt opt)
  end

  defp span_opt(opt) do
    template_text_opt(opt)
    |> Map.merge(base_opt opt, only: [:size])
  end

  defp base_opt(opt) do
    %{
      flex: opt[:flex],
      position: opt[:position],
      margin: opt[:margin],
      align: opt[:align],
      gravity: opt[:gravity],
      size: opt[:size],
      backgroundColor: opt[:background_color]
    }
  end

  defp base_opt(opt, [only: keys]) do
    base_opt(opt) |> Map.take(keys)
  end

  defp base_opt(opt, [except: keys]) do
    base_opt(opt)
    |> Map.split(keys)
    |> case do {_, map} -> map end
  end

  defp offset_opt(opt) do
    %{
      offsetTop: opt[:offset_top],
      offsetBottom: opt[:offset_bottom],
      offsetStart: opt[:offset_start],
      offsetEnd: opt[:offset_end]
    }
  end

  defp padding_opt(opt) do
    %{
      paddingAll: opt[:padding_all],
      paddingTop: opt[:padding_top],
      paddingBottom: opt[:padding_bottom],
      paddingStart: opt[:padding_start],
      paddingEnd: opt[:padding_end]
    }
  end

  # --- actions --- #

  @doc """
  Returns a postback event to the server containing
  the given string
  """

  def action({:postback, data}) do
    %{type: "postback", data: data}
  end

  @doc """
  Redirect the user to a specific URI
  """

  def action({:uri, uri}) do
    %{type: "uri", uri: uri}
  end

  # --- helper --- #

  @doc """
  removes values ​​determined as false from the map
  """

  def map_filter({:ok, map}) do
    Map.keys(map)
    |> Enum.reduce(map, fn key, acc ->
      v = acc[key]
      cond do
        !v ->
          Map.delete(acc, key)
        is_list(v) ->
          Map.put(acc, key, Enum.map(v, &map_filter/1))
        is_map(v) ->
          Map.put(acc, key, map_filter(v))
        true ->
          acc
      end
    end)
  end

  def map_filter(v) do
    if is_map(v), do: map_filter({:ok, v}), else: v
  end

  @doc """
  Guarantees that the values ​​sent will always be a list
  """

  def guarantee_list(v), do: List.flatten [v]
end
