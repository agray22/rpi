--Gives 10 second delay to kill if needed

FileToExecute="axg.lua"
l = file.list()
for k,v in pairs(l) do
  if k == FileToExecute then
    print("*** You've got 10 seconds to stop timer ***")
    tmr.alarm(0, 10000, 0, function()
      print("Executing ".. FileToExecute)
      dofile(FileToExecute)
    end)
  end
end
