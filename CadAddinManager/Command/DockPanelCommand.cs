using System.Windows.Forms;
using System.Windows.Forms.Integration;
#if BRICS
using Teigha.Runtime;
using Bricscad.Windows;
#else
using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.Windows;
#endif
using CadAddinManager.View.Control;

namespace CadAddinManager.Command;

public class DockPanelCommand : ICadCommand
{
    static PaletteSet pLogControl = null;
    [CommandMethod("AddinManagerDockPanel")]
    public override void Execute()
    {
        if(pLogControl == null)
        {
            pLogControl = new PaletteSet("Trace/Debug Output");
            pLogControl.MinimumSize = new System.Drawing.Size(300, 300);
            pLogControl.DockEnabled = (DockSides)((int)DockSides.Left + (int)DockSides.Right);
            pLogControl.Style = PaletteSetStyles.ShowAutoHideButton
                                |  PaletteSetStyles.ShowCloseButton
                                |  PaletteSetStyles.ShowPropertiesMenu
                                |  PaletteSetStyles.Snappable;
            LogControl Lib = new LogControl();
            ElementHost host = new ElementHost();
            host.AutoSize = true;
            host.Dock = DockStyle.Right;
            host.Child = Lib;
            pLogControl.Add("LogControl", host);
        }

        pLogControl.KeepFocus = true;
        pLogControl.Visible = !pLogControl.Visible;
    }
}