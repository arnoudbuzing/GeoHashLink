BeginPackage["WolframExternalFunctions`GeoHashLink`"];

GeoHashEncode::usage = "GeoHashEncode[geo, precision] encodes a GeoPosition object into a geohash string with the given precision.";
GeoHashDecode::usage = "GeoHashDecode[hash] decodes a geohash string into a GeoPosition object and a GeoBoundsRegion object.";
GeoHashNeighbors::usage = "GeoHashNeighbors[hash] returns a list of geohash strings that are the neighbors of the given geohash string.";
GeoHashDimensions::usage = "GeoHashDimensions[precision] returns the dimensions of the geohash box for the given precision.";

Begin["`Private`"];

this = DirectoryName[$InputFileName];
lib = FileNameJoin[{this, "Libraries", $SystemID, "libgeohash.dylib"}];

GeoBoxDimension = {"CDouble", "CDouble"};
GeoCoord = {"CDouble", "CDouble", "CDouble", "CDouble", "CDouble", "CDouble"};
CharStar = "RawPointer"::["UnsignedInteger8"];
CharStarStar = "RawPointer"::[CharStar];

geoHashEncode = ForeignFunctionLoad[lib, "geohash_encode", {"CDouble", "CDouble", "CInt"} -> CharStar];
geoHashDecode = ForeignFunctionLoad[lib, "geohash_decode", {CharStar} -> GeoCoord];
geoHashNeighbors = ForeignFunctionLoad[lib, "geohash_neighbors", {CharStar} -> CharStarStar];
geoHashDimensionsForPrecision = ForeignFunctionLoad[lib, "geohash_dimensions_for_precision", {"CInt"} -> GeoBoxDimension];

GeoHashEncode[geo_GeoPosition, precision_Integer] := RawMemoryImport[
    geoHashEncode[
        QuantityMagnitude[Latitude[geo]], 
        QuantityMagnitude[Longitude[geo]], 
        precision
    ], 
    "String"
];

GeoHashDecode[hash_String] := Module[{lat, long, north, east, south, west},
   {lat, long, north, east, south, west} = geoHashDecode[hash];
   <|
        "GeoPosition" -> GeoPosition[{lat, long}], 
        "GeoBoundsRegion" -> GeoBoundsRegion[{{south, north}, {west, east}}]
    |>
];

GeoHashNeighbors[hash_String] := Module[{ptr},
    ptr = geoHashNeighbors[hash];
    RawMemoryImport[#, "String"] & /@ RawMemoryImport[ptr, {"List", 8}]
];

GeoHashDimensions[precision_Integer] := geoHashDimensionsForPrecision[precision]

End[];
EndPackage[];