#importonce

.filenamespace rle

.assert "rle empty", encode(List()).string(), List().add(0).string()
.assert "rle 1 element", encode(List().add(3)).string(), List().add(1, 3, 0).string()
.assert "rle 2 different", encode(List().add(3, 4)).string(), List().add(-2, 3, 4, 0).string()
.assert "rle 2 same", encode(List().add(3, 3)).string(), List().add(2, 3, 0).string()
.assert "rle 2 same, 2 different", encode(List().add(3, 3, 4, 2)).string(), List().add(2, 3, -2, 4, 2, 0).string()
.assert "rle 2 same, 2 same", encode(List().add(3, 3, 4, 4)).string(), List().add(2, 3, 2, 4, 0).string()
.assert "rle 2 same, 2 same", encode(List().add(3, 3, 5, 4, 4, 4)).string(), List().add(2, 3, 1, 5, 3, 4, 0).string()
.assert "rle 2 different, 2 same", encode(List().add(4, 2, 3, 3)).string(), List().add(-2, 4, 2, 2, 3, 0).string()
{
    .var mlist = List()
    .for (var i = 0; i < 130; i++) {
        .eval mlist.add(3)
    }
    .assert "rle long run", encode(mlist).string(), List().add(127, 3, 3, 3, 0).string()
}
{
    .var mlist = List()
    .for (var i = 0; i < 127; i++) {
        .eval mlist.add(3)
    }
    .assert "rle long run, exactly 127", encode(mlist).string(), List().add(127, 3, 0).string()
}
{
    .var mlist = List()
    .for (var i = 0; i < 127; i++) {
        .eval mlist.add(i)
    }
    .assert "rle long different run, exactly 127", encode(mlist).string(), List().add(-127).addAll(mlist).add(0).string()
}
{
    .var alist = List()
    .for (var i = 0; i < 127; i++) {
        .eval alist.add(i)
    }
    .var mlist = List().addAll(alist).add(128, 129)
    .assert "rle long different run, exactly 129", encode(mlist).string(), List().add(-127).addAll(alist).add(-2, 128, 129, 0).string()
}
{
    .var alist = List()
    .for (var i = 0; i < 127; i++) {
        .eval alist.add(i)
    }
    .var mlist = List().addAll(alist).add(1, 1)
    .assert "rle long different run, exactly 127, followed by two same", encode(mlist).string(), List().add(-127).addAll(alist).add(2, 1, 0).string()
}

.struct Chunk {length, value}

.function split_chunks(bytelist) {
    .var value
    .var chunks = List()

    // work on copy of list and add termination marker to eliminate special end case
    .var list = List().addAll(bytelist).add("end")

    // dummy chunk to eliminate special initial case
    .var chunk = Chunk(0, "begin")

    .for (var i = 0; i < list.size(); i++) {
        .eval value = list.get(i)
        .if (value == chunk.value) {
            .eval chunk.length += 1
        } else {
            .eval chunks.add(chunk)
            .eval chunk = Chunk(1, value)
        }
    }

    .return chunks.remove(0)
}

.function encode(list) {
    .var result = List()

    .var chunks = split_chunks(list)

    // dummy chunk to eliminate special end case
    .eval chunks.add(Chunk(0, "end"))

    .var changing = List()

    .for (var i = 0; i < chunks.size(); i++) {
        .var chunk = chunks.get(i)
        .if (chunk.length == 1) {
            .eval changing.add(chunk.value)
            .if (changing.size() == 127) {
                .eval result.add(-changing.size()).addAll(changing)
                .eval changing = List()
            }
        } else {
            .if (changing.size() > 0) {
                .var size = changing.size()
                .eval result.add((size == 1) ? 1 : -size).addAll(changing)
                .eval changing = List()
            }
            .while (chunk.length > 127) {
                .eval result.add(127, chunk.value)
                .eval chunk.length -= 127
            }
            .eval result.add(chunk.length, chunk.value)
        }
    }

    // remove dummy chunk "end" value
    .return result.remove(result.size() - 1)
}

.macro @rleImportFile(filename) {
    // Load the file into the variable data
    .var data = LoadBinary(filename)
    .var list = List()
    .for (var i = 0; i < data.getSize(); i++) {
        .eval list.add(data.get(i))
    }
    .var rleList = encode(list)
    .fill rleList.size(), rleList.get(i)
}
