using XML
using LZMA


function convert_lzma_file_to_xml(file_path::AbstractString, xml_root_dir::AbstractString)

    # Créer le répertoire s'il n'existe pas
    if !isdir(xml_root_dir)
        mkdir(xml_root_dir)
    end

    # Décompresser le fichier et écrire le résultat dans un nouveau fichier XML
    xml_file_path = joinpath(xml_root_dir, splitext(basename(file_path))[1] * ".xml")
    open(xml_file_path, "w") do xml_file
        write(xml_file, readlzma(file_path))
    end
end