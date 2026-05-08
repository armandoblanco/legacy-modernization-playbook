---
applyTo: "src/App.Wpf/**/*.{cs,xaml}"
description: Convenciones para WPF + MVVM con CommunityToolkit.Mvvm en migración VB6 → .NET 8
---

# Convenciones WPF + MVVM

Aplica a archivos en `src/App.Wpf/`. Asume que el ADR-001 eligió WPF y el ADR-004 eligió CommunityToolkit.Mvvm.

## Estructura de carpetas

```
src/App.Wpf/
├── App.xaml + App.xaml.cs           Generic Host, DI, Serilog
├── MainWindow.xaml                  Shell de la app (típicamente MDI o navegación)
├── ViewModels/
│   ├── <Feature>/                   Un ViewModel por View, no shared
│   │   └── <Feature>ViewModel.cs
├── Views/
│   ├── <Feature>/
│   │   └── <Feature>View.xaml + .cs
├── Resources/
│   ├── Styles.xaml                  Estilos compartidos
│   └── Themes/                      Si hay tema corporativo
└── Converters/                      IValueConverter cuando se necesitan
```

## ViewModels

**Reglas obligatorias:**

1. Heredar de `ObservableObject` de CommunityToolkit.Mvvm
2. Usar `[ObservableProperty]` en CAMPOS privados (source generators crean la propiedad pública)
3. Usar `[RelayCommand]` en MÉTODOS para crear comandos
4. Inyección de casos de uso por **primary constructor**
5. **NUNCA lógica de negocio en ViewModel** — solo orquestación, presentación y binding
6. ViewModels registrados en DI (`AddTransient<<Feature>ViewModel>`)

### Ejemplo de ViewModel correcto

```csharp
namespace App.Wpf.ViewModels.Clientes;

internal sealed partial class ClientesListaViewModel(
    BuscarClientesUseCase buscarClientes,
    ILogger<ClientesListaViewModel> logger) : ObservableObject
{
    [ObservableProperty]
    private string _filtroNombre = string.Empty;

    [ObservableProperty]
    private bool _isBusy;

    public ObservableCollection<ClienteDto> Clientes { get; } = new();

    [RelayCommand]
    private async Task BuscarAsync(CancellationToken cancellationToken)
    {
        IsBusy = true;
        try
        {
            var query = new BuscarClientesQuery { Nombre = FiltroNombre };
            var result = await buscarClientes.ExecuteAsync(query, cancellationToken);

            if (!result.IsSuccess)
            {
                logger.LogWarning("Búsqueda falló: {Error}", result.Error);
                return;
            }

            Clientes.Clear();
            foreach (var cliente in result.Value!)
                Clientes.Add(cliente);
        }
        finally
        {
            IsBusy = false;
        }
    }
}
```

Notas:
- `partial class` requerido para que los source generators de CommunityToolkit.Mvvm funcionen
- Campos privados con underscore + `[ObservableProperty]` → propiedad pública generada
- Método privado con `[RelayCommand]` → comando público generado (`BuscarCommand`)
- `IsBusy` se setea en finally para garantizar reset

## Views

### Code-behind

**Mínimo absoluto.** Solo `InitializeComponent()`:

```csharp
namespace App.Wpf.Views.Clientes;

public partial class ClientesListaView
{
    public ClientesListaView()
    {
        InitializeComponent();
    }
}
```

**NO** colocar lógica en code-behind. Si es event handler, usar `EventToCommand` o `Behaviors`.

### XAML

```xml
<UserControl x:Class="App.Wpf.Views.Clientes.ClientesListaView"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             xmlns:vm="clr-namespace:App.Wpf.ViewModels.Clientes"
             d:DataContext="{d:DesignInstance Type=vm:ClientesListaViewModel}">
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="10">
            <TextBox Text="{Binding FiltroNombre, UpdateSourceTrigger=PropertyChanged}" 
                     Width="200" Margin="0,0,10,0"/>
            <Button Content="Buscar" 
                    Command="{Binding BuscarCommand}"
                    IsEnabled="{Binding IsBusy, Converter={StaticResource InverseBoolConverter}}"/>
        </StackPanel>
        
        <DataGrid Grid.Row="1" 
                  ItemsSource="{Binding Clientes}"
                  AutoGenerateColumns="False"
                  CanUserAddRows="False"
                  IsReadOnly="True">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding Id}" Width="80"/>
                <DataGridTextColumn Header="Nombre" Binding="{Binding Nombre}" Width="*"/>
                <DataGridTextColumn Header="Email" Binding="{Binding Email}" Width="200"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</UserControl>
```

Notas:
- `d:DataContext` con `DesignInstance` para IntelliSense en designer
- `UpdateSourceTrigger=PropertyChanged` cuando se necesita reactividad inmediata
- `CanUserAddRows="False"` y `IsReadOnly="True"` por default en DataGrid (evitar edición accidental)
- `AutoGenerateColumns="False"` siempre — control explícito

## DataContext

- **Inyectar el ViewModel desde DI** en el constructor de la View, NO `new` manual
- O usar `ViewModelLocator` pattern si la app es grande

```csharp
public partial class ClientesListaView
{
    public ClientesListaView(ClientesListaViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
    }
}
```

Y registrar la View en DI también:

```csharp
services.AddTransient<ClientesListaView>();
services.AddTransient<ClientesListaViewModel>();
```

## Bindings

- **Mode explícito** cuando importa: `OneWay`, `TwoWay`, `OneTime`
- **`UpdateSourceTrigger=PropertyChanged`** para campos de filtro reactivos
- **`StringFormat`** para formatear valores: `Text="{Binding Total, StringFormat=C2}"`
- **Converters** en `Converters/`, registrados como `StaticResource` en `App.xaml`
- **Validación**: `INotifyDataErrorInfo` en ViewModel, NO `IDataErrorInfo` (obsoleto)

## Mapeo de controles VB6 → WPF

| Control VB6 | Equivalente WPF | Notas |
| --- | --- | --- |
| `Form` | `Window` o `UserControl` | Window para shell, UserControl para vistas dentro |
| `MDIForm` | `Window` con `TabControl` o `Frame` | MDI clásico no existe en WPF; reemplazar por tabs |
| `TextBox` | `TextBox` | Igual |
| `Label` | `Label` o `TextBlock` | TextBlock más liviano si no necesita target |
| `CommandButton` | `Button` | |
| `ComboBox` | `ComboBox` | `ItemsSource` con binding |
| `ListBox` | `ListBox` o `ListView` | |
| `MSFlexGrid` | `DataGrid` | API completamente distinta — modelo MVVM |
| `Frame` | `GroupBox` o `Border` | |
| `OptionButton` | `RadioButton` | |
| `CheckBox` | `CheckBox` | |
| `Timer` | `DispatcherTimer` | |
| `MSCAL Calendar` | `Calendar` o `DatePicker` | |
| `Image` (ImageBox) | `Image` | |
| `Picture Box` | `Image` o `Border` con `Background` | |

## OCX bloqueados en UI

Cuando un OCX no tiene reemplazo (Crystal Reports, LeadTools, PISPEC):

```xml
<Border BorderBrush="DarkRed" BorderThickness="2" Padding="20" Margin="10">
    <StackPanel>
        <TextBlock Text="Funcionalidad pendiente" FontWeight="Bold" Foreground="DarkRed"/>
        <TextBlock Text="Este módulo requiere integración con [Servicio]." Margin="0,5,0,0"/>
        <TextBlock Text="Ver ADR-XXX en docs/adr/" Margin="0,5,0,0"/>
    </StackPanel>
</Border>
```

Y en el ViewModel, comando que lanza `NotImplementedException` con referencia a ADR.

## Performance

- **DataGrid con virtualización** habilitada (default en WPF, pero validar)
- **`VirtualizingStackPanel.IsVirtualizing="True"`** para listas grandes
- **NO bind a colecciones grandes sin virtualización**
- **`IsAsync=True`** en bindings de propiedades costosas

## Theming

Si el ADR especifica branding corporativo:

- Estilos en `Resources/Styles.xaml`
- ResourceDictionaries por componente, mergedlocked en `App.xaml`
- Colores como `<SolidColorBrush x:Key="..."/>` reutilizables

## Lo prohibido

- ❌ Lógica de negocio en code-behind
- ❌ `MessageBox.Show` en ViewModels (usar `IDialogService` inyectado)
- ❌ `Application.Current.MainWindow` o `Window` referenciado desde ViewModel
- ❌ Acceso directo a controles XAML desde ViewModel
- ❌ `Dispatcher.Invoke` en ViewModels (en su lugar, marshal en services si necesario)
- ❌ Strings hardcoded de UI en código (usar `.resx` si hay i18n)
- ❌ Eventos de controles directamente en code-behind para lógica de negocio
- ❌ `new ViewModel()` manual; siempre vía DI
