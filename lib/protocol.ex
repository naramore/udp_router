defmodule Protocol.UDP.Header do
  @moduledoc false

  defstruct srcport:     0,
            destport:    0,
            length:      0,
            checksum:    <<0, 0>>
  @type t :: %Protocol.UDP.Header{
    srcport: non_neg_integer,
    destport: non_neg_integer,
    length: non_neg_integer,
    checksum: binary}

  @doc false
  @spec decode(binary) :: {:ok, Protocol.UDP.Header.t} | {:error, term}
  def decode(<<srcport   :: unsigned-integer-size(16),
              destport  :: unsigned-integer-size(16),
              length     :: unsigned-integer-size(16),
              checksum   :: binary-size(2),
              _payload   :: binary>>) do
    {:ok, %Protocol.UDP.Header{
      srcport: srcport,
      destport: destport,
      length: length,
      checksum: checksum
    }}
  end
  def decode(data), do: {:error, {:unrecognized_format, data}}

  @doc false
  @spec encode(Protocol.UDP.Header.t) :: {:ok, binary} | {:error, term}
  def encode(%Protocol.UDP.Header{srcport: s, destport: d, length: l, checksum: c}) do
    {:ok, <<s :: unsigned-integer-size(16),
            d :: unsigned-integer-size(16),
            l :: unsigned-integer-size(16),
            c :: binary-size(2)>>}
  end
  def encode(data), do: {:error, {:unrecognized_format, data}}
end

defmodule Protocol.UDP do
  @moduledoc false

  @bytes_in_header 8

  defstruct header: %Protocol.UDP.Header{},
            data: <<>>
  @type t :: %Protocol.UDP{
    header: Protocol.UDP.Header.t,
    data: binary
  }

  @doc false
  @spec decode(binary) :: {:ok, Protocol.UDP.t} | {:error, term}
  def decode(<< _header :: bytes-size(@bytes_in_header), payload :: binary >> = data) do
    case Protocol.UDP.Header.decode(data) do
      {:ok, header} -> {:ok, %Protocol.UDP{header: header, data: payload}}
      {:error, reason} -> {:error, reason}
    end
  end
  def decode(data), do: {:error, {:unrecognized_format, data}}

  @doc false
  @spec encode(Protocol.UDP.t) :: {:ok, binary} | {:error, term}
  def encode(%Protocol.UDP{header: h, data: d}) do
    case Protocol.UDP.Header.encode(h) do
      {:ok, header} -> {:ok, <<header :: binary-size(8), d :: binary>>}
      {:error, reason} -> {:error, reason}
    end
  end
  def encode(data), do: {:error, {:unrecognized_format, data}}
end
