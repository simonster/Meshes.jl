include("io/2dm.jl")
include("io/amf.jl")
include("io/obj.jl")
include("io/off.jl")
include("io/ply.jl")
include("io/stl.jl")
include("io/threejs.jl")

using ZipFile

export mesh

function mesh(path::String; format=:autodetect, topology=false)
    io = open(path, "r")
    fmt = format
    msh = nothing
    if fmt == :autodetect
        if endswith(path, ".stl")
            header = ascii(readbytes(io, 5))
            if lowercase(header) == "solid"
                fmt = :asciistl
            else
                readbytes(io, 75) # throw out header
                fmt = :binarystl
            end
        elseif endswith(path, ".ply")
            fmt = :ply
        elseif endswith(path, ".2dm")
            fmt = :(2dm)
        elseif endswith(path, ".obj")
            fmt = :obj
        elseif endswith(path, ".amf")
            fmt = :amf
        elseif endswith(path, ".off")
            fmt = :off
        elseif endswith(path, ".js")
            fmt = :threejs
        else
            error("Could not identify mesh format")
        end
    end
    if fmt == :binarystl
        msh = importBinarySTL(io, topology=topology, read_header=true)
    elseif fmt == :asciistl
        msh = importAsciiSTL(io, topology=topology)
    elseif fmt == :ply
        msh = importPly(io, topology=topology)
    elseif fmt == :(2dm)
        msh = import2dm(io)
    elseif fmt == :obj
        msh = importOBJ(io)
    elseif fmt == :amf
        # check if zipped
        header = readbytes(io,4)
        close(io)
        if header == [0x50,0x4b,0x03,0x04]
            contents = ZipFile.Reader(path)
            io = contents.files[1] # TODO: analyize contents
        else # uncompressed
            io = open(path, "r")
        end
        msh = importAMF(io)
    elseif fmt == :off
        msh = importOFF(io)
    elseif fmt == :threejs
        msh = importThreejs(io)
    else
        error("Could not identify mesh format")
    end
    close(io)
    return msh
end
