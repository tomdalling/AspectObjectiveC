
FILE_NAME_FOR_INSERT = ARGV[0]
BEGIN_INSERT_LINE = "//begin #{File.basename(__FILE__)}"
END_INSERT_LINE = "//end #{File.basename(__FILE__)}"
DONT_INSERT_LINE = "//dont insert"

if(!File.exists?(FILE_NAME_FOR_INSERT) || !File.writable?(FILE_NAME_FOR_INSERT))
    abort("Can't find or can't write to #{FILE_NAME_FOR_INSERT}")
end

newFileContent = ""
fileToModify = File.new(FILE_NAME_FOR_INSERT, "r")

if(fileToModify.gets.chomp == DONT_INSERT_LINE)
    exit
else
    fileToModify.seek(0)
end

#Include the old stuff up to BEGIN_INSERT_LINE of file
while true
    line = fileToModify.gets
    if line.nil?
        abort("hit EOF before finding \"#{BEGIN_INSERT_LINE}\"") 
    elsif line.chomp == BEGIN_INSERT_LINE
        break
    else
        newFileContent += line
    end
end

newFileContent += BEGIN_INSERT_LINE + "\n"

#Include the new stuff from STDIN
while line = STDIN.gets
    newFileContent += line
end

#EXCLUDE the old stuff up to END_INSERT_LINE of file
while true
    line = fileToModify.gets
    if line.nil?
        abort("hit EOF before finding \"#{END_INSERT_LINE}\"")
    elsif line.chomp == END_INSERT_LINE
        break
    end
end

newFileContent += END_INSERT_LINE + "\n"

#include the old stuff after END_INSERT_LINE of file
while line = fileToModify.gets
    newFileContent += line
end

#write new file contents over old
fileToModify.close
fileToModify = File.new(FILE_NAME_FOR_INSERT, "w")
fileToModify.write(newFileContent)
fileToModify.close

