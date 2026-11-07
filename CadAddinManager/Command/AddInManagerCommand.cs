using System.Diagnostics;
#if BRICS
using Bricscad.ApplicationServices.Core;
using Teigha.Runtime;
#else
using Autodesk.AutoCAD.ApplicationServices.Core;
using Autodesk.AutoCAD.Runtime;
#endif
using CadAddinManager.Model;
using Exception = System.Exception;

namespace CadAddinManager.Command;


public class AddInManagerManual : ICadCommand
{
    
    [CommandMethod("AddInManagerManual",CommandFlags.Session)]
    public override void Execute()
    {
        Trace.Listeners.Clear();
        Trace.Listeners.Clear();
        CodeListener codeListener = new CodeListener();
        Trace.Listeners.Add(codeListener);
        AddinManagerBase.Instance.ExecuteCommand(false);
    }
}

public class AddInManagerFaceLess  : ICadCommand
{
    [CommandMethod("AddInManagerFaceLess",CommandFlags.Session)]
    public override void Execute()
    {
        try
        {
            AddinManagerBase.Instance.ExecuteCommand(true);
        }
        catch (Exception e)
        {
            MessageBox.Show(e.ToString());
            Trace.WriteLine(e.Message);
        }
    }
}

