defmodule TamagymWeb.GymLive do
  use TamagymWeb, :live_view

  require Logger

  alias Tamagym.{Accounts, AI, Gym}
  alias Tamagym.Gym.{AIPlanner, BodyMap, Catalogue, State}

  @days_en [
    {"Monday", "1"},
    {"Tuesday", "2"},
    {"Wednesday", "3"},
    {"Thursday", "4"},
    {"Friday", "5"},
    {"Saturday", "6"},
    {"Sunday", "0"}
  ]
  @days_es [
    {"Lunes", "1"},
    {"Martes", "2"},
    {"Miércoles", "3"},
    {"Jueves", "4"},
    {"Viernes", "5"},
    {"Sábado", "6"},
    {"Domingo", "0"}
  ]

  @es %{
    "Home" => "Inicio",
    "Plan" => "Plan",
    "Workout" => "Entreno",
    "Stats" => "Estadísticas",
    "Progress & history" => "Progreso e historial",
    "Workouts" => "Entrenos",
    "This month" => "Este mes",
    "Week streak" => "Racha semanal",
    "Weight 30d" => "Peso 30d",
    "Activity — last 12 months" => "Actividad — últimos 12 meses",
    "by workouts" => "por entrenos",
    "Workout activity" => "Actividad de entreno",
    "Less" => "Menos",
    "More" => "Más",
    "Muscle balance" => "Equilibrio muscular",
    "by completed sets, 30d" => "por series completadas, 30d",
    "No completed sets in this period." => "No hay series completadas en este período.",
    "Exercise progress" => "Progreso por ejercicio",
    "Log your body weight to see progress here." => "Registra tu peso para ver el progreso aquí.",
    "Finish your first workout to see progress curves here." =>
      "Termina tu primer entreno para ver aquí las curvas de progreso.",
    "Best:" => "Mejor:",
    "Exercises" => "Ejercicios",
    "Settings" => "Ajustes",
    "Sign in" => "Iniciar sesión",
    "Create account" => "Crear cuenta",
    "Email" => "Correo electrónico",
    "Password" => "Contraseña",
    "or" => "o",
    "Confirm password" => "Confirmar contraseña",
    "Continue without an account" => "Continuar sin una cuenta",
    "Your data stays in this browser and will not sync to other devices." =>
      "Tus datos permanecen en este navegador y no se sincronizan con otros dispositivos.",
    "Your workouts, routines, and progress." => "Tus entrenos, rutinas y progreso.",
    "Welcome" => "Bienvenido",
    "Today" => "Hoy",
    "Rest day" => "Día de descanso",
    "Start" => "Empezar",
    "Resume" => "Continuar",
    "Recent workouts" => "Entrenos recientes",
    "This week" => "Esta semana",
    "Workout done" => "Entreno completado",
    "in progress" => "en curso",
    "Build my own plan" => "Crear mi plan",
    "Create your first routine, choose its exercises, and assign it to your week." =>
      "Crea tu primera rutina, elige sus ejercicios y asígnala a tu semana.",
    "Log" => "Registrar",
    "Goal" => "Objetivo",
    "reached!" => "¡alcanzado!",
    "to gain" => "por ganar",
    "to lose" => "por perder",
    "No entries yet — log your weight to start the curve." =>
      "Todavía no hay registros: añade tu peso para iniciar la gráfica.",
    "No workouts yet." => "Todavía no hay entrenos.",
    "Weekly schedule" => "Horario semanal",
    "Routines" => "Rutinas",
    "New routine" => "Nueva rutina",
    "Create a routine first, then assign it here." => "Crea primero una rutina y asígnala aquí.",
    "Weekly plan:" => "Plan semanal:",
    "changed for this day" => "cambiado para este día",
    "Pick what to train today." => "Elige qué entrenar hoy.",
    "Rest / skip this day" => "Descansar / saltar este día",
    "Back to weekly plan" => "Volver al plan semanal",
    "Rest" => "Descanso",
    "Save" => "Guardar",
    "Delete" => "Eliminar",
    "Add exercise" => "Añadir ejercicio",
    "No exercises yet — add your first one." => "Aún no hay ejercicios; añade el primero.",
    "Changes save automatically" => "Los cambios se guardan automáticamente",
    "What this session hits" => "Qué trabaja esta sesión",
    "Traps" => "Trapecio",
    "Shoulders" => "Hombros",
    "Chest" => "Pecho",
    "Upper back" => "Espalda alta",
    "Serratus" => "Serrato",
    "Biceps" => "Bíceps",
    "Triceps" => "Tríceps",
    "Forearms" => "Antebrazos",
    "Abs" => "Abdominales",
    "Obliques" => "Oblicuos",
    "Lower back" => "Espalda baja",
    "Glutes" => "Glúteos",
    "Quads" => "Cuádriceps",
    "Hamstrings" => "Isquiotibiales",
    "Adductors" => "Aductores",
    "Hip flexors" => "Flexores de cadera",
    "Calves" => "Gemelos",
    "Shins" => "Tibiales",
    "Search exercises" => "Buscar ejercicios",
    "sets" => "series",
    "reps" => "repeticiones",
    "weight" => "peso",
    "Remove" => "Quitar",
    "Start workout" => "Empezar entreno",
    "Freestyle workout" => "Entreno libre",
    "Add a routine first" => "Añade una rutina primero",
    "Add set" => "Añadir serie",
    "Remove set" => "Quitar serie",
    "Warm-up" => "Calentamiento",
    "Add warm-up set" => "Añadir serie de calentamiento",
    "Remove warm-up" => "Quitar calentamiento",
    "Burst" => "Ráfaga",
    "Remove burst" => "Quitar ráfaga",
    "Drop" => "Bajada",
    "Remove drop" => "Quitar bajada",
    "Drop-set / rest-pause" => "Series descendentes / rest-pause",
    "None" => "Ninguno",
    "Drop-set" => "Serie descendente",
    "Rest-pause" => "Rest-pause",
    "Last set" => "Última serie",
    "Drops" => "Bajadas",
    "Weight drop (%)" => "Bajada de peso (%)",
    "Rest-pause reps" => "Repeticiones rest-pause",
    "Set techniques" => "Técnicas por serie",
    "Extra reps" => "Repeticiones extra",
    "Choose a technique only for the sets that should use it — for example, make just the last set a drop set." =>
      "Elige una técnica solo para las series que la necesiten; por ejemplo, usa una bajada únicamente en la última serie.",
    "Rest (s)" => "Descanso (s)",
    "Each work set adds the selected number of drops with no rest, reducing the weight each time." =>
      "Cada serie añade las bajadas seleccionadas sin descanso, reduciendo el peso cada vez.",
    "The session starts with a warm-up, then splits the extra reps into short-rest bursts." =>
      "La sesión empieza con calentamiento y divide las repeticiones extra en ráfagas con descansos cortos.",
    "Decrease weight" => "Reducir peso",
    "Increase weight" => "Aumentar peso",
    "Decrease reps" => "Reducir repeticiones",
    "Increase reps" => "Aumentar repeticiones",
    "body weight" => "peso corporal",
    "added" => "añadido",
    "Last time" => "Última vez",
    "Move up" => "Subir",
    "Move down" => "Bajar",
    "Swap exercise" => "Cambiar ejercicio",
    "Remove exercise" => "Quitar ejercicio",
    "The sets you logged for this exercise in this session will be lost." =>
      "Se perderán las series que registraste para este ejercicio en esta sesión.",
    "This removes the exercise from your current session." =>
      "Esto quita el ejercicio de tu sesión actual.",
    "Finish workout?" => "¿Terminar entreno?",
    "unfinished sets will remain uncompleted." => "series sin terminar quedarán incompletas.",
    "All sets are complete. Great work." => "Todas las series están completas. Buen trabajo.",
    "Continue workout" => "Continuar entreno",
    "Discard workout?" => "¿Descartar entreno?",
    "The sets you logged in this session will be lost." =>
      "Se perderán las series registradas en esta sesión.",
    "Finish workout" => "Terminar entreno",
    "Cancel workout" => "Cancelar entreno",
    "Discard" => "Descartar",
    "Finish" => "Terminar",
    "Exercise" => "Ejercicio",
    "Prev" => "Anterior",
    "Next" => "Siguiente",
    "Freestyle workout — add your first exercise." => "Entreno libre: añade tu primer ejercicio.",
    "Set" => "Serie",
    "Done" => "Hecho",
    "History" => "Historial",
    "Total workouts" => "Entrenos totales",
    "Completed sets" => "Series completadas",
    "Total volume" => "Volumen total",
    "Body weight" => "Peso corporal",
    "Add body weight" => "Añadir peso corporal",
    "Log body weight" => "Registrar peso corporal",
    "Save & start workout" => "Guardar y empezar entreno",
    "Start without weighing in" => "Empezar sin pesarme",
    "Recent weigh-ins" => "Pesajes recientes",
    "No entries yet." => "Todavía no hay registros.",
    "Exercise library" => "Biblioteca de ejercicios",
    "exercises with animations" => "ejercicios con animaciones",
    "Search…" => "Buscar…",
    "All" => "Todos",
    "Any equipment" => "Cualquier equipo",
    "Create your own exercise" => "Crea tu propio ejercicio",
    "name + body part, no animation" => "nombre y parte del cuerpo, sin animación",
    "No match" => "Sin resultados",
    "Show more" => "Mostrar más",
    "Add to my plan" => "Añadir a mi plan",
    "How to" => "Cómo hacerlo",
    "instructions in English" => "instrucciones en inglés",
    "tap to pause" => "toca para pausar",
    "tap to play" => "toca para reproducir",
    "Minimize" => "Minimizar",
    "Minimize animation" => "Minimizar animación",
    "Expand animation" => "Ampliar animación",
    "Best" => "Mejor",
    "Custom exercise" => "Ejercicio personalizado",
    "Name" => "Nombre",
    "Body part" => "Parte del cuerpo",
    "Equipment" => "Equipamiento",
    "Add" => "Añadir",
    "Account" => "Cuenta",
    "Using without an account" => "Usando la aplicación sin una cuenta",
    "Saved only in this browser." => "Guardado solo en este navegador.",
    "Sign in or create an account" => "Iniciar sesión o crear una cuenta",
    "Sign out" => "Cerrar sesión",
    "Language" => "Idioma",
    "English" => "Inglés",
    "Spanish" => "Español",
    "General" => "General",
    "Weight unit" => "Unidad de peso",
    "Note: switching units only changes the label — logged numbers are not converted." =>
      "Nota: cambiar de unidad solo cambia la etiqueta; los valores registrados no se convierten.",
    "During a workout" => "Durante un entreno",
    "Rest timer" => "Temporizador de descanso",
    "Skip" => "Saltar",
    "Rest-pause rest" => "Descanso rest-pause",
    "Off" => "Desactivado",
    "Appearance" => "Apariencia",
    "Theme" => "Tema",
    "Dark" => "Oscuro",
    "Light" => "Claro",
    "System" => "Sistema",
    "Accent color" => "Color de acento",
    "Saved with your account." => "Guardado con tu cuenta.",
    "Plans and workout data are saved in SQLite." =>
      "Los planes y entrenos se guardan en SQLite.",
    "Sign out?" => "¿Cerrar sesión?",
    "Your latest changes are saved to your account before this browser signs out." =>
      "Tus últimos cambios se guardan en tu cuenta antes de cerrar la sesión en este navegador.",
    "Cancel" => "Cancelar",
    "Saved" => "Guardado",
    "Local only" => "Solo local",
    "No routines yet." => "Todavía no hay rutinas.",
    "Workout deleted." => "Entreno eliminado.",
    "Routine deleted." => "Rutina eliminada.",
    "AI planner" => "Planificador con IA",
    "Generate routine with AI" => "Generar rutina con IA",
    "Build a new commercial-gym routine for this weekday." =>
      "Crea una nueva rutina de gimnasio para este día de la semana.",
    "Choose muscle groups" => "Elige grupos musculares",
    "Select between 1 and 3 muscle groups." => "Selecciona entre 1 y 3 grupos musculares.",
    "Choose at least one muscle group." => "Elige al menos un grupo muscular.",
    "Back" => "Espalda",
    "Legs" => "Piernas",
    "Core" => "Core",
    "Generate routine" => "Generar rutina",
    "Generating routine…" => "Generando rutina…",
    "Review AI routine" => "Revisa la rutina de IA",
    "Create and assign" => "Crear y asignar",
    "A new routine will be created and assigned to this weekday. Existing routines are kept." =>
      "Se creará una rutina nueva y se asignará a este día. Las rutinas existentes se conservarán.",
    "AI routine created and assigned." => "Rutina de IA creada y asignada.",
    "Plan my next 7 days" => "Planificar mis próximos 7 días",
    "Generate a complete commercial-gym split from today, including recovery days." =>
      "Genera una rutina dividida y completa para gimnasio desde hoy, incluidos los días de recuperación.",
    "Choose your goal" => "Elige tu objetivo",
    "Strength" => "Fuerza",
    "Hypertrophy" => "Hipertrofia",
    "General fitness" => "Forma física general",
    "Fat loss" => "Pérdida de grasa",
    "Generate plan" => "Generar plan",
    "Generating your plan…" => "Generando tu plan…",
    "Review your 7-day plan" => "Revisa tu plan de 7 días",
    "Apply plan" => "Aplicar plan",
    "Generate again" => "Generar de nuevo",
    "Applying also replaces your recurring weekly schedule." =>
      "Al aplicarlo también se reemplaza tu horario semanal recurrente.",
    "AI plan applied to this week and your weekly schedule." =>
      "Plan de IA aplicado a esta semana y a tu horario semanal.",
    "AI model" => "Modelo de IA",
    "Your selected model is saved per account or browser." =>
      "El modelo seleccionado se guarda por cuenta o navegador.",
    "Find alternatives with AI" => "Buscar alternativas con IA",
    "Why can't you do this exercise?" => "¿Por qué no puedes hacer este ejercicio?",
    "Equipment unavailable" => "Equipamiento no disponible",
    "Pain or discomfort" => "Dolor o molestia",
    "Equipment is occupied" => "El equipo está ocupado",
    "Too difficult today" => "Demasiado difícil hoy",
    "Other reason" => "Otro motivo",
    "Finding alternatives…" => "Buscando alternativas…",
    "Choose an alternative" => "Elige una alternativa",
    "Use this exercise" => "Usar este ejercicio",
    "The AI service could not create a valid result. Please try again." =>
      "El servicio de IA no pudo crear un resultado válido. Inténtalo de nuevo.",
    "AI-generated plans are suggestions. Review the exercises and loads before training." =>
      "Los planes generados por IA son sugerencias. Revisa los ejercicios y las cargas antes de entrenar."
  }

  @impl true
  def mount(_params, _session, socket) do
    state =
      case socket.assigns.current_scope do
        %{user: user} -> user |> Gym.get_data() |> State.clean()
        _scope -> State.clean(%{})
      end

    socket =
      socket
      |> assign(:state, state)
      |> assign(:locale, State.locale(state))
      |> assign(:auth_mode, "login")
      |> assign(:search, "")
      |> assign(:body_part, "")
      |> assign(:equipment, "")
      |> assign(:catalogue_results, Enum.take(Catalogue.all(), 40))
      |> assign(:routine_id, nil)
      |> assign(:week_offset, 0)
      |> assign(:stats_range, 90)
      |> assign(:stats_exercise, nil)
      |> assign(:modal, nil)
      |> assign(:ai_models, AI.models())
      |> assign(:ai_draft, nil)
      |> assign(:ai_day_draft, nil)
      |> assign(:ai_muscle_groups, [])
      |> assign(:ai_alternatives, [])
      |> assign(:ai_loading, nil)
      |> assign(:ai_error, nil)
      |> assign(:page_title, "tamagym")
      |> assign(:today, Date.utc_today())
      |> assign(:auth_form, to_form(%{"email" => "", "password" => ""}, as: :user))
      |> apply_preferences()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    auth_mode = if params["auth"] == "register", do: "register", else: "login"
    routine_id = params["id"]
    title = page_title(socket.assigns.live_action, socket.assigns.locale)

    {:noreply, assign(socket, auth_mode: auth_mode, routine_id: routine_id, page_title: title)}
  end

  @impl true
  def handle_event("lv:clear-flash", %{"kind" => kind}, socket) do
    kind = if kind == "error", do: :error, else: :info
    {:noreply, clear_flash(socket, kind)}
  end

  def handle_event(
        "guest:restore",
        %{"state" => state},
        %{assigns: %{current_scope: nil}} = socket
      )
      when is_map(state) do
    state = State.clean(state)
    scope = %{user: nil, local_only?: true}

    {:noreply,
     socket
     |> assign(current_scope: scope, state: state, locale: State.locale(state))
     |> apply_preferences()}
  end

  def handle_event("guest:restore", _params, socket), do: {:noreply, socket}

  def handle_event("guest:start", _params, socket) do
    scope = %{user: nil, local_only?: true}

    {:noreply,
     socket
     |> assign(:current_scope, scope)
     |> persist(State.clean(%{}))}
  end

  def handle_event("guest:leave", _params, socket) do
    {:noreply,
     socket
     |> push_event("guest:leave", %{})
     |> assign(current_scope: nil, state: State.clean(%{}))}
  end

  def handle_event("nav", %{"to" => to}, socket)
      when to in ["/home", "/plan", "/workout", "/stats", "/library", "/settings"] do
    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("week:move", %{"direction" => direction}, socket) do
    delta = if direction == "next", do: 1, else: -1
    {:noreply, update(socket, :week_offset, &(&1 + delta))}
  end

  def handle_event("week:today", _params, socket), do: {:noreply, assign(socket, :week_offset, 0)}

  def handle_event("stats:range", %{"days" => days}, socket) do
    {:noreply, assign(socket, :stats_range, State.integer(days, 90))}
  end

  def handle_event("stats:exercise-open", _params, socket) do
    {:noreply, assign(socket, :modal, :stats_exercise)}
  end

  def handle_event("stats:exercise-select", %{"id" => exercise_id}, socket) do
    {:noreply, assign(socket, stats_exercise: exercise_id, modal: nil)}
  end

  def handle_event("workout:open", %{"id" => workout_id}, socket) do
    {:noreply, assign(socket, :modal, {:workout, workout_id})}
  end

  def handle_event("activity:open", %{"date" => date}, socket) do
    workouts = Enum.filter(socket.assigns.state["workouts"], &(&1["d"] == date))

    modal =
      case workouts do
        [workout] -> {:workout, workout["id"]}
        _workouts -> {:activity, date}
      end

    {:noreply, assign(socket, :modal, modal)}
  end

  def handle_event("modal:close", _params, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("bodyweight:open", _params, socket),
    do: {:noreply, assign(socket, :modal, :bodyweight)}

  def handle_event("goal:open", _params, socket), do: {:noreply, assign(socket, :modal, :goal)}

  def handle_event("goal:save", %{"weight" => weight}, socket) do
    value = State.number(weight)

    if value > 0 do
      {:noreply,
       socket
       |> assign(:modal, nil)
       |> persist(Map.put(socket.assigns.state, "targetW", value))}
    else
      {:noreply, put_flash(socket, :error, "Enter a valid weight.")}
    end
  end

  def handle_event("goal:remove", _params, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(Map.put(socket.assigns.state, "targetW", nil))}
  end

  def handle_event("ai:week-open", _params, socket) do
    if AI.configured?() do
      {:noreply,
       assign(socket,
         modal: :ai_week,
         ai_draft: nil,
         ai_error: nil,
         ai_loading: nil
       )}
    else
      {:noreply, put_flash(socket, :error, "AI planning is not configured.")}
    end
  end

  def handle_event("ai:week-generate", %{"goal" => goal}, socket) do
    model = AI.selected_model(socket.assigns.state)

    if goal in AIPlanner.goals() and model do
      state = socket.assigns.state
      today = socket.assigns.today

      {:noreply,
       socket
       |> assign(modal: :ai_week_loading, ai_loading: :week, ai_error: nil, ai_draft: nil)
       |> start_async(:ai_week, fn -> AIPlanner.generate_week(state, goal, model, today) end)}
    else
      {:noreply, put_flash(socket, :error, "Choose a valid goal and AI model.")}
    end
  end

  def handle_event("ai:week-apply", _params, socket) do
    case socket.assigns.ai_draft do
      %{"days" => _days} = draft ->
        state = State.apply_ai_week(socket.assigns.state, draft, socket.assigns.today)

        {:noreply,
         socket
         |> assign(modal: nil, ai_draft: nil, ai_error: nil)
         |> persist(state)
         |> put_flash(
           :info,
           t(socket.assigns.locale, "AI plan applied to this week and your weekly schedule.")
         )}

      _draft ->
        {:noreply, socket}
    end
  end

  def handle_event("workout:prepare", %{"id" => id}, socket) do
    cond do
      socket.assigns.state["active"] ->
        {:noreply, push_patch(socket, to: ~p"/workout")}

      id in [nil, ""] ->
        {:noreply, push_patch(socket, to: ~p"/workout")}

      true ->
        routine_id = if id == "freestyle", do: nil, else: id
        {:noreply, assign(socket, :modal, {:bodyweight_start, routine_id})}
    end
  end

  def handle_event("bodyweight:save", %{"weight" => weight}, socket) do
    value = State.number(weight)

    if value > 0 do
      state = State.add_body_weight(socket.assigns.state, value)

      case socket.assigns.modal do
        {:bodyweight_start, routine_id} ->
          {:noreply,
           socket
           |> assign(:modal, nil)
           |> persist(State.start_workout(state, routine_id, value))
           |> push_patch(to: ~p"/workout")}

        _modal ->
          {:noreply, socket |> assign(:modal, nil) |> persist(state)}
      end
    else
      {:noreply, put_flash(socket, :error, "Enter a valid weight.")}
    end
  end

  def handle_event("workout:start-without-weight", _params, socket) do
    case socket.assigns.modal do
      {:bodyweight_start, routine_id} ->
        {:noreply,
         socket
         |> assign(:modal, nil)
         |> persist(State.start_workout(socket.assigns.state, routine_id))
         |> push_patch(to: ~p"/workout")}

      _modal ->
        {:noreply, socket}
    end
  end

  def handle_event("custom:open", _params, socket),
    do: {:noreply, assign(socket, :modal, :custom_exercise)}

  def handle_event("exercise:open", %{"id" => id}, socket) do
    {:noreply, assign(socket, :modal, {:exercise, id})}
  end

  def handle_event("exercise:add-plan", %{"id" => id}, socket) do
    {:noreply, assign(socket, :modal, {:add_exercise, id})}
  end

  def handle_event(
        "exercise:add-to-routine",
        %{"exercise" => exercise_id, "routine" => routine_id},
        socket
      ) do
    state = State.add_routine_exercise(socket.assigns.state, routine_id, exercise_id)

    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(state)
     |> put_flash(:info, "Exercise added to your plan.")}
  end

  def handle_event("exercise:add-to-new-routine", %{"exercise" => exercise_id}, socket) do
    {state, routine_id} =
      State.add_routine(socket.assigns.state, t(socket.assigns.locale, "New routine"))

    state = State.add_routine_exercise(state, routine_id, exercise_id)

    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(state)
     |> push_patch(to: ~p"/plan/r/#{routine_id}")}
  end

  def handle_event("filter:bodypart", %{"value" => value}, socket) do
    socket = assign(socket, body_part: value, equipment: "")
    {:noreply, assign(socket, :catalogue_results, filtered_catalogue(socket.assigns, 80))}
  end

  def handle_event("filter:equipment", %{"value" => value}, socket) do
    socket = assign(socket, :equipment, value)
    {:noreply, assign(socket, :catalogue_results, filtered_catalogue(socket.assigns, 80))}
  end

  def handle_event("catalogue:more", _params, socket) do
    {:noreply,
     assign(
       socket,
       :catalogue_results,
       filtered_catalogue(socket.assigns, length(socket.assigns.catalogue_results) + 40)
     )}
  end

  def handle_event("routine:new", _params, socket) do
    {state, routine_id} =
      State.add_routine(socket.assigns.state, t(socket.assigns.locale, "New routine"))

    {:noreply, socket |> persist(state) |> push_patch(to: ~p"/plan/r/#{routine_id}")}
  end

  def handle_event("routine:update", params, socket) do
    id = socket.assigns.routine_id

    attrs = %{
      "name" => String.trim(params["name"] || ""),
      "emoji" => params["emoji"] || "dumbbell"
    }

    {:noreply, persist(socket, State.update_routine(socket.assigns.state, id, attrs))}
  end

  def handle_event("routine:delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> persist(State.delete_routine(socket.assigns.state, id))
     |> put_flash(:info, t(socket.assigns.locale, "Routine deleted."))
     |> push_patch(to: ~p"/plan")}
  end

  def handle_event("day:open", %{"date" => date}, socket) do
    {:noreply, assign(socket, :modal, {:day_override, date})}
  end

  def handle_event("day:assign", %{"date" => date, "routine" => routine_id}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.assign_date(socket.assigns.state, date, routine_id))}
  end

  def handle_event("schedule:open", %{"day" => day}, socket) do
    {:noreply, assign(socket, :modal, {:day_schedule, day})}
  end

  def handle_event("schedule:assign", %{"day" => day, "routine" => routine_id}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.assign_day(socket.assigns.state, day, routine_id))}
  end

  def handle_event("ai:day-open", %{"day" => day}, socket) do
    if AI.configured?() and day in ~w(0 1 2 3 4 5 6) do
      {:noreply,
       assign(socket,
         modal: {:ai_day, day},
         ai_day_draft: nil,
         ai_muscle_groups: [],
         ai_loading: nil,
         ai_error: nil
       )}
    else
      {:noreply, put_flash(socket, :error, "AI planning is not configured.")}
    end
  end

  def handle_event("ai:day-muscle-toggle", %{"group" => group}, socket) do
    selected = socket.assigns.ai_muscle_groups

    selected =
      cond do
        group not in AIPlanner.muscle_groups() -> selected
        group in selected -> List.delete(selected, group)
        length(selected) < 3 -> selected ++ [group]
        true -> selected
      end

    {:noreply, assign(socket, ai_muscle_groups: selected, ai_error: nil)}
  end

  def handle_event("ai:day-generate", %{"day" => day}, socket) do
    groups = socket.assigns.ai_muscle_groups
    model = AI.selected_model(socket.assigns.state)

    if day in ~w(0 1 2 3 4 5 6) and groups != [] and model do
      state = socket.assigns.state

      {:noreply,
       socket
       |> assign(
         modal: {:ai_day_loading, day},
         ai_day_draft: nil,
         ai_loading: :day,
         ai_error: nil
       )
       |> start_async({:ai_day, day}, fn -> AIPlanner.generate_day(state, groups, day, model) end)}
    else
      {:noreply,
       assign(socket, ai_error: t(socket.assigns.locale, "Choose at least one muscle group."))}
    end
  end

  def handle_event("ai:day-apply", %{"day" => day}, socket) do
    case socket.assigns.ai_day_draft do
      %{"exercises" => _exercises} = draft ->
        state = State.apply_ai_day(socket.assigns.state, day, draft, socket.assigns.today)

        {:noreply,
         socket
         |> assign(modal: nil, ai_day_draft: nil, ai_muscle_groups: [], ai_error: nil)
         |> persist(state)
         |> put_flash(:info, t(socket.assigns.locale, "AI routine created and assigned."))}

      _draft ->
        {:noreply, socket}
    end
  end

  def handle_event("search", %{"query" => query}, socket) do
    socket = assign(socket, :search, query)
    {:noreply, assign(socket, :catalogue_results, filtered_catalogue(socket.assigns, 80))}
  end

  def handle_event("routine:exercise-picker", _params, socket) do
    {:noreply,
     open_workout_exercise_picker(
       socket,
       {:routine_exercise_picker, socket.assigns.routine_id}
     )}
  end

  def handle_event("routine:exercise-open", %{"index" => index}, socket) do
    {:noreply,
     assign(socket, :modal, {
       :routine_exercise,
       socket.assigns.routine_id,
       State.integer(index)
     })}
  end

  def handle_event("routine:add-exercise", %{"id" => exercise_id}, socket) do
    routine =
      Enum.find(socket.assigns.state["routines"], &(&1["id"] == socket.assigns.routine_id))

    index = if routine, do: length(routine["ex"]), else: 0

    state =
      State.add_routine_exercise(socket.assigns.state, socket.assigns.routine_id, exercise_id)

    {:noreply,
     socket
     |> assign(:modal, {:routine_exercise, socket.assigns.routine_id, index})
     |> persist(state)}
  end

  def handle_event("routine:remove-exercise", %{"index" => index}, socket) do
    state =
      State.remove_routine_exercise(
        socket.assigns.state,
        socket.assigns.routine_id,
        State.integer(index)
      )

    {:noreply, socket |> assign(:modal, nil) |> persist(state)}
  end

  def handle_event(
        "routine:step-exercise",
        %{"index" => index, "field" => field, "direction" => direction},
        socket
      )
      when field in ~w(sets reps weight) do
    index = State.integer(index)

    routine =
      Enum.find(socket.assigns.state["routines"], &(&1["id"] == socket.assigns.routine_id))

    config = routine && Enum.at(routine["ex"], index)

    state =
      if config do
        {step, minimum} =
          if field == "weight", do: {2.5, 0.0}, else: {1, if(field == "sets", do: 1, else: 0)}

        current =
          if field == "weight",
            do: State.number(config[field]),
            else: State.integer(config[field], minimum)

        value = max(minimum, current + if(direction == "up", do: step, else: -step))
        value = if field == "weight", do: value, else: trunc(value)

        attrs = %{field => value}

        attrs =
          if field == "sets" do
            attrs
            |> Map.put("setTechniques", routine_set_techniques(config, value))
            |> Map.put("intensifier", nil)
          else
            attrs
          end

        State.configure_routine_exercise(
          socket.assigns.state,
          socket.assigns.routine_id,
          index,
          attrs
        )
      else
        socket.assigns.state
      end

    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "routine:set-technique",
        %{"index" => index, "set" => set_index, "type" => type},
        socket
      )
      when type in ~w(none dropset restpause) do
    index = State.integer(index)
    set_index = State.integer(set_index)
    config = routine_config(socket.assigns.state, socket.assigns.routine_id, index)

    state =
      if config do
        technique =
          case type do
            "dropset" ->
              %{"type" => "dropset", "count" => 1, "pct" => 20}

            "restpause" ->
              %{
                "type" => "restpause",
                "totalReps" => max(1, State.integer(config["reps"], 10)),
                "restSec" => max(5, State.integer(socket.assigns.state["restPauseSec"], 15))
              }

            "none" ->
              nil
          end

        techniques = config |> routine_set_techniques() |> List.replace_at(set_index, technique)

        State.configure_routine_exercise(
          socket.assigns.state,
          socket.assigns.routine_id,
          index,
          %{"setTechniques" => techniques, "intensifier" => nil}
        )
      else
        socket.assigns.state
      end

    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "routine:set-technique-step",
        %{
          "index" => index,
          "set" => set_index,
          "field" => field,
          "direction" => direction
        },
        socket
      )
      when field in ~w(count pct totalReps restSec) do
    index = State.integer(index)
    set_index = State.integer(set_index)
    config = routine_config(socket.assigns.state, socket.assigns.routine_id, index)
    techniques = config && routine_set_techniques(config)
    technique = techniques && Enum.at(techniques, set_index)

    state =
      if technique do
        {step, minimum} = if field in ~w(pct restSec), do: {5, 5}, else: {1, 1}
        current = State.integer(technique[field], minimum)
        value = max(minimum, current + if(direction == "up", do: step, else: -step))
        value = if field == "pct", do: min(value, 90), else: value
        techniques = List.replace_at(techniques, set_index, Map.put(technique, field, value))

        State.configure_routine_exercise(
          socket.assigns.state,
          socket.assigns.routine_id,
          index,
          %{"setTechniques" => techniques, "intensifier" => nil}
        )
      else
        socket.assigns.state
      end

    {:noreply, persist(socket, state)}
  end

  def handle_event("routine:configure-exercise", params, socket) do
    index = State.integer(params["index"])
    config = routine_config(socket.assigns.state, socket.assigns.routine_id, index)
    attrs = routine_exercise_attrs(params)

    attrs =
      if config do
        attrs
        |> Map.put("setTechniques", routine_set_techniques(config, attrs["sets"]))
        |> Map.put("intensifier", nil)
      else
        attrs
      end

    state =
      State.configure_routine_exercise(
        socket.assigns.state,
        socket.assigns.routine_id,
        index,
        attrs
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event("workout:start", %{"id" => id}, socket) do
    handle_event("workout:prepare", %{"id" => id}, socket)
  end

  def handle_event("workout:move", %{"direction" => direction}, socket) do
    active = socket.assigns.state["active"]
    delta = if direction == "next", do: 1, else: -1
    current = ((active && active["cur"]) || 0) + delta
    {:noreply, persist(socket, State.set_active_index(socket.assigns.state, current))}
  end

  def handle_event("workout:reorder", %{"direction" => direction}, socket) do
    delta = if direction == "down", do: 1, else: -1
    {:noreply, persist(socket, State.move_active_exercise(socket.assigns.state, delta))}
  end

  def handle_event("workout:exercise-picker", _params, socket) do
    {:noreply, open_workout_exercise_picker(socket, :workout_exercise)}
  end

  def handle_event("workout:swap-open", %{"index" => index}, socket) do
    {:noreply, open_workout_exercise_picker(socket, {:swap_exercise, State.integer(index)})}
  end

  def handle_event("ai:alternatives-open", %{"index" => index}, socket) do
    if AI.configured?() do
      {:noreply,
       assign(socket,
         modal: {:ai_alternative_reason, State.integer(index)},
         ai_alternatives: [],
         ai_error: nil,
         ai_loading: nil
       )}
    else
      {:noreply, put_flash(socket, :error, "AI planning is not configured.")}
    end
  end

  def handle_event(
        "ai:alternatives-generate",
        %{"index" => index, "reason" => reason},
        socket
      ) do
    index = State.integer(index)
    model = AI.selected_model(socket.assigns.state)

    if reason in AIPlanner.alternative_reasons() and model do
      state = socket.assigns.state

      {:noreply,
       socket
       |> assign(
         modal: {:ai_alternatives, index},
         ai_loading: :alternatives,
         ai_alternatives: [],
         ai_error: nil
       )
       |> start_async({:ai_alternatives, index}, fn ->
         AIPlanner.alternatives(state, index, reason, model)
       end)}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "ai:alternative-select",
        %{"id" => exercise_id, "index" => index},
        socket
      ) do
    allowed? = Enum.any?(socket.assigns.ai_alternatives, &(&1["exercise_id"] == exercise_id))

    if allowed? do
      {:noreply,
       socket
       |> assign(modal: nil, ai_alternatives: [], ai_error: nil)
       |> persist(
         State.swap_active_exercise(socket.assigns.state, State.integer(index), exercise_id)
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("workout:swap-exercise", %{"id" => exercise_id, "index" => index}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(
       State.swap_active_exercise(socket.assigns.state, State.integer(index), exercise_id)
     )}
  end

  def handle_event("workout:add-exercise", %{"id" => exercise_id}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.add_active_exercise(socket.assigns.state, exercise_id))}
  end

  def handle_event("workout:remove-open", %{"index" => index}, socket) do
    {:noreply, assign(socket, :modal, {:remove_exercise, State.integer(index)})}
  end

  def handle_event("workout:remove-exercise", %{"index" => index}, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.remove_active_exercise(socket.assigns.state, State.integer(index)))}
  end

  def handle_event(
        "set:step",
        %{"entry" => entry, "set" => set_index, "field" => field, "direction" => direction},
        socket
      )
      when field in ~w(w r) do
    state =
      State.step_set(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        field,
        if(direction == "up", do: 1, else: -1)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event("set:update", params, socket) do
    entry_index = State.integer(params["entry"])
    set_index = State.integer(params["set"])

    attrs = %{
      "w" => max(0.0, State.number(params["w"])),
      "r" => max(0, State.integer(params["r"]))
    }

    {:noreply,
     persist(socket, State.update_set(socket.assigns.state, entry_index, set_index, attrs))}
  end

  def handle_event("set:toggle", %{"entry" => entry, "set" => set_index}, socket) do
    entry_index = State.integer(entry)
    set_index = State.integer(set_index)
    was_done = set_done?(socket.assigns.state, entry_index, set_index)
    warmup? = warmup_set?(socket.assigns.state, entry_index, set_index)
    state = State.toggle_set(socket.assigns.state, entry_index, set_index)
    socket = persist(socket, state)
    rest_seconds = max(0, State.integer(state["restSec"], 90))

    socket =
      if !was_done && !warmup? && rest_seconds > 0 && unfinished_sets(state) > 0 do
        push_event(socket, "rest:start", %{seconds: rest_seconds})
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("set:add", %{"entry" => entry}, socket) do
    {:noreply, persist(socket, State.add_set(socket.assigns.state, State.integer(entry)))}
  end

  def handle_event("set:add-warmup", %{"entry" => entry}, socket) do
    {:noreply, persist(socket, State.add_warmup_set(socket.assigns.state, State.integer(entry)))}
  end

  def handle_event("drop:add", %{"entry" => entry, "set" => set_index}, socket) do
    state = State.add_drop(socket.assigns.state, State.integer(entry), State.integer(set_index))
    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "drop:step",
        %{
          "entry" => entry,
          "set" => set_index,
          "drop" => drop,
          "field" => field,
          "direction" => direction
        },
        socket
      )
      when field in ~w(w r) do
    state =
      State.step_drop(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        State.integer(drop),
        field,
        if(direction == "up", do: 1, else: -1)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "drop:remove",
        %{"entry" => entry, "set" => set_index, "drop" => drop},
        socket
      ) do
    state =
      State.remove_drop(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        State.integer(drop)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event("burst:add", %{"entry" => entry, "set" => set_index}, socket) do
    state =
      State.add_burst(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        State.integer(socket.assigns.state["restPauseSec"], 15)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "burst:step",
        %{"entry" => entry, "set" => set_index, "burst" => burst, "direction" => direction},
        socket
      ) do
    state =
      State.step_burst(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        State.integer(burst),
        if(direction == "up", do: 1, else: -1)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event(
        "burst:remove",
        %{"entry" => entry, "set" => set_index, "burst" => burst},
        socket
      ) do
    state =
      State.remove_burst(
        socket.assigns.state,
        State.integer(entry),
        State.integer(set_index),
        State.integer(burst)
      )

    {:noreply, persist(socket, state)}
  end

  def handle_event("rest:start", %{"seconds" => seconds}, socket) do
    {:noreply, push_event(socket, "rest:start", %{seconds: max(1, State.integer(seconds, 15))})}
  end

  def handle_event("set:remove", %{"entry" => entry, "set" => set_index}, socket) do
    state = State.remove_set(socket.assigns.state, State.integer(entry), State.integer(set_index))
    {:noreply, persist(socket, state)}
  end

  def handle_event("workout:finish-open", _params, socket) do
    {:noreply, assign(socket, :modal, :finish_workout)}
  end

  def handle_event("workout:cancel-open", _params, socket) do
    {:noreply, assign(socket, :modal, :discard_workout)}
  end

  def handle_event("workout:finish", _params, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.finish_workout(socket.assigns.state))
     |> push_patch(to: ~p"/history")}
  end

  def handle_event("workout:cancel", _params, socket) do
    {:noreply,
     socket
     |> assign(:modal, nil)
     |> persist(State.cancel_workout(socket.assigns.state))
     |> push_patch(to: ~p"/home")}
  end

  def handle_event("workout:delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> persist(State.delete_workout(socket.assigns.state, id))
     |> put_flash(:info, t(socket.assigns.locale, "Workout deleted."))}
  end

  def handle_event("bodyweight:add", %{"weight" => weight}, socket) do
    number = State.number(weight)

    state =
      if number > 0,
        do: State.add_body_weight(socket.assigns.state, number),
        else: socket.assigns.state

    {:noreply, persist(socket, state)}
  end

  def handle_event("bodyweight:delete", %{"index" => index}, socket) do
    {:noreply,
     persist(socket, State.delete_body_weight(socket.assigns.state, State.integer(index)))}
  end

  def handle_event("custom:add", params, socket) do
    state =
      State.add_custom_exercise(
        socket.assigns.state,
        params["name"],
        params["body_part"],
        params["equipment"]
      )

    {:noreply, socket |> assign(:modal, nil) |> persist(state)}
  end

  def handle_event("setting:open", %{"key" => key}, socket)
      when key in ~w(lang restSec restPauseSec) do
    {:noreply, assign(socket, :modal, {:setting, key})}
  end

  def handle_event("ai:model-open", _params, socket) do
    if socket.assigns.ai_models == [] do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :modal, :ai_model)}
    end
  end

  def handle_event("ai:model-select", %{"model" => model}, socket) do
    if AI.model_allowed?(model) do
      state = Map.put(socket.assigns.state, "aiModel", model)
      {:noreply, socket |> assign(:modal, nil) |> persist(state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("setting:set", %{"key" => key, "setting" => value}, socket) do
    {key, value} = preference(%{"key" => key, "value" => value})
    state = State.update_preference(socket.assigns.state, key, value)

    {:noreply,
     socket
     |> assign(modal: nil, locale: State.locale(state))
     |> persist(state)
     |> apply_preferences()}
  end

  def handle_event("account:signout-open", _params, socket) do
    {:noreply, assign(socket, :modal, :sign_out)}
  end

  def handle_event("preference:update", params, socket) do
    {key, value} = preference(params)
    state = State.update_preference(socket.assigns.state, key, value)

    {:noreply,
     socket
     |> assign(:locale, State.locale(state))
     |> persist(state)
     |> apply_preferences()}
  end

  @impl true
  def handle_async(:ai_week, {:ok, {:ok, draft}}, socket) do
    {:noreply,
     assign(socket,
       modal: :ai_week_preview,
       ai_draft: draft,
       ai_loading: nil,
       ai_error: nil
     )}
  end

  def handle_async(:ai_week, result, socket) do
    Logger.error("[Tamagym.AI] week task failed result=#{AI.error_summary(result)}")

    {:noreply,
     assign(socket,
       modal: :ai_week,
       ai_loading: nil,
       ai_error: ai_error_message(socket.assigns.locale)
     )}
  end

  def handle_async({:ai_day, day}, {:ok, {:ok, draft}}, socket) do
    {:noreply,
     assign(socket,
       modal: {:ai_day_preview, day},
       ai_day_draft: draft,
       ai_loading: nil,
       ai_error: nil
     )}
  end

  def handle_async({:ai_day, day}, result, socket) do
    Logger.error("[Tamagym.AI] day task failed day=#{day} result=#{AI.error_summary(result)}")

    {:noreply,
     assign(socket,
       modal: {:ai_day, day},
       ai_loading: nil,
       ai_error: ai_error_message(socket.assigns.locale)
     )}
  end

  def handle_async({:ai_alternatives, index}, {:ok, {:ok, alternatives}}, socket) do
    {:noreply,
     assign(socket,
       modal: {:ai_alternatives, index},
       ai_alternatives: alternatives,
       ai_loading: nil,
       ai_error: nil
     )}
  end

  def handle_async({:ai_alternatives, index}, result, socket) do
    Logger.error(
      "[Tamagym.AI] alternatives task failed index=#{index} result=#{AI.error_summary(result)}"
    )

    {:noreply,
     assign(socket,
       modal: {:ai_alternatives, index},
       ai_loading: nil,
       ai_error: ai_error_message(socket.assigns.locale)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div id="guest-store" phx-hook="GuestStore">
        <.login
          :if={is_nil(@current_scope)}
          auth_mode={@auth_mode}
          auth_form={@auth_form}
          locale={@locale}
        />
        <div :if={@current_scope} id="gym-app">
          <.screen assigns={assigns} />
          <.navigation action={@live_action} locale={@locale} state={@state} />
          <.modal
            :if={@modal}
            modal={@modal}
            state={@state}
            locale={@locale}
            search={@search}
            results={@catalogue_results}
            ai_models={@ai_models}
            ai_draft={@ai_draft}
            ai_day_draft={@ai_day_draft}
            ai_muscle_groups={@ai_muscle_groups}
            ai_alternatives={@ai_alternatives}
            ai_loading={@ai_loading}
            ai_error={@ai_error}
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :auth_mode, :string, required: true
  attr :auth_form, :map, required: true
  attr :locale, :string, required: true

  def login(assigns) do
    ~H"""
    <div class="lv-login">
      <div class="lv-brand">
        <div class="lv-brand-mark"><.icon name="hero-dumbbell" /></div>
        <h1>tamagym</h1>
        <p class="muted">{t(@locale, "Your workouts, routines, and progress.")}</p>
      </div>
      <div class="card">
        <div class="lv-auth-tabs">
          <.link patch={~p"/?auth=login"} class={if @auth_mode == "login", do: "on"}>{t(
            @locale,
            "Sign in"
          )}</.link>
          <.link patch={~p"/?auth=register"} class={if @auth_mode == "register", do: "on"}>{t(
            @locale,
            "Create account"
          )}</.link>
        </div>
        <.form for={@auth_form} id="auth-form" action={~p"/session"} method="post" class="lv-form">
          <input type="hidden" name="mode" value={@auth_mode} />
          <.input
            field={@auth_form[:email]}
            type="email"
            label={t(@locale, "Email")}
            autocomplete="email"
            required
          />
          <.input
            field={@auth_form[:password]}
            type="password"
            label={t(@locale, "Password")}
            autocomplete={if @auth_mode == "register", do: "new-password", else: "current-password"}
            minlength="8"
            required
          />
          <.input
            :if={@auth_mode == "register"}
            name="confirmation"
            type="password"
            label={t(@locale, "Confirm password")}
            autocomplete="new-password"
            minlength="8"
            required
          />
          <.button type="submit" icon="hero-user-circle">{t(
            @locale,
            if(@auth_mode == "register", do: "Create account", else: "Sign in")
          )}</.button>
        </.form>
        <div class="lv-divider">{t(@locale, "or")}</div>
        <.button class="btn tinted" icon="hero-dumbbell" phx-click="guest:start">{t(
          @locale,
          "Continue without an account"
        )}</.button>
        <p class="dim small" style="text-align:center;margin-top:10px">
          {t(@locale, "Your data stays in this browser and will not sync to other devices.")}
        </p>
      </div>
    </div>
    """
  end

  attr :assigns, :map, required: true

  def screen(%{assigns: page_assigns} = assigns) do
    assigns = assign(assigns, page_assigns)

    ~H"""
    <.home
      :if={@live_action == :home}
      state={@state}
      locale={@locale}
      today={@today}
      current_scope={@current_scope}
      week_offset={@week_offset}
    />
    <.plan
      :if={@live_action == :plan}
      state={@state}
      locale={@locale}
      ai_configured={@ai_models != []}
    />
    <.routine
      :if={@live_action == :routine}
      state={@state}
      locale={@locale}
      routine_id={@routine_id}
    />
    <.workout
      :if={@live_action == :workout}
      state={@state}
      locale={@locale}
      search={@search}
      results={@catalogue_results}
      ai_configured={@ai_models != []}
    />
    <.stats
      :if={@live_action == :stats}
      state={@state}
      locale={@locale}
      range={@stats_range}
      selected_exercise={@stats_exercise}
    />
    <.history :if={@live_action == :history} state={@state} locale={@locale} />
    <.library
      :if={@live_action == :library}
      state={@state}
      locale={@locale}
      search={@search}
      results={@catalogue_results}
      body_part={@body_part}
      equipment={@equipment}
    />
    <.settings
      :if={@live_action == :settings}
      state={@state}
      locale={@locale}
      current_scope={@current_scope}
      ai_models={@ai_models}
    />
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :today, Date, required: true
  attr :current_scope, :map, required: true
  attr :week_offset, :integer, required: true

  def home(assigns) do
    routine = State.effective_routine(assigns.state, assigns.today)

    done_today =
      Enum.find(
        Enum.reverse(assigns.state["workouts"]),
        &(&1["d"] == Date.to_iso8601(assigns.today))
      )

    body_weights = assigns.state["bodyweight"]
    body_weight = List.last(body_weights)
    previous_weight = if length(body_weights) > 1, do: Enum.at(body_weights, -2), else: nil

    delta =
      if body_weight && previous_weight, do: body_weight["w"] - previous_weight["w"], else: nil

    week_days = week_days(assigns.state, assigns.today, assigns.week_offset, assigns.locale)

    assigns =
      assign(assigns,
        routine: routine,
        done_today: done_today,
        body_weight: body_weight,
        delta: delta,
        week_days: week_days
      )

    ~H"""
    <div class="narrow">
      <header class="hdr">
        <div>
          <h1>{greeting(@current_scope, @locale)}</h1>
          <div class="sub">{date_label(@locale, @today)}</div>
        </div>
        <button
          class="iconbtn"
          phx-click="nav"
          phx-value-to="/settings"
          aria-label={t(@locale, "Settings")}
        >
          <.icon name="hero-cog-6-tooth" />
        </button>
      </header>

      <div class="card">
        <div class="row between" style="margin-bottom:8px">
          <button
            class="iconbtn week-arrow"
            phx-click="week:move"
            phx-value-direction="previous"
            aria-label="Previous week"
          >
            <.icon name="hero-chevron-left" />
          </button>
          <button class="small muted" style="font-weight:500" phx-click="week:today">{week_label(
            @week_days,
            @week_offset,
            @locale
          )}</button>
          <button
            class="iconbtn week-arrow"
            phx-click="week:move"
            phx-value-direction="next"
            aria-label="Next week"
          >
            <.icon name="hero-chevron-right" />
          </button>
        </div>
        <div class="week">
          <div :for={day <- @week_days} class={["wday", day.today? && "today"]}>
            <div class="lbl">{day.label}</div><div class="num">{day.date.day}</div><div class={[
              "dot",
              day.kind
            ]}>
            </div>
          </div>
        </div>
        <button
          class="today-row"
          phx-click={if @state["active"], do: "workout:prepare", else: "day:open"}
          phx-value-date={Date.to_iso8601(@today)}
          phx-value-id={(@routine && @routine["id"]) || ""}
        >
          <div class="row" style="gap:9px;min-width:0">
            <span class="lrow-i" style={today_icon_style(@state, @routine, @done_today)}>
              <.icon name={today_icon(@state, @routine, @done_today)} />
            </span>
            <div style="min-width:0;text-align:left">
              <div class="lbl2">{t(@locale, "Today")}</div>
              <div class="ttl">{today_title(@state, @routine, @done_today, @locale)}</div>
            </div>
          </div>
          <span :if={@state["active"]} class="tag resume">{t(@locale, "Resume")}</span>
          <span :if={!@state["active"] && @done_today} class="tag done">{t(@locale, "Done")}</span>
          <.icon
            :if={!@state["active"] && !@done_today}
            name="hero-chevron-right"
            class="chev"
          />
        </button>
      </div>

      <div :if={@state["routines"] == [] && is_nil(@state["active"])} class="card">
        <div class="row" style="gap:10px;margin-bottom:6px">
          <span class="lrow-i"><.icon name="hero-sparkles" /></span>
          <div class="big" style="font-size:22px">{t(@locale, "Welcome")}</div>
        </div>
        <div class="muted small" style="margin-bottom:12px">
          {t(@locale, "Create your first routine, choose its exercises, and assign it to your week.")}
        </div>
        <button class="btn primary" phx-click="nav" phx-value-to="/plan"><.icon name="hero-plus" />{t(
          @locale,
          "Build my own plan"
        )}</button>
      </div>

      <div class="card">
        <div class="row between" style="margin-bottom:6px">
          <h2 style="margin:0">{t(@locale, "Body weight")}</h2>
          <div class="row body-weight-actions">
            <button
              class={["btn", "plain", "sm", "home-goal", @state["targetW"] && "active"]}
              phx-click="goal:open"
            ><.icon name="hero-target" />{if @state["targetW"],
              do: format_number(@state["targetW"]),
              else: t(@locale, "Goal")}</button>
            <button class="btn plain sm home-log" phx-click="bodyweight:open"><.icon name="hero-plus" />{t(
              @locale,
              "Log"
            )}</button>
          </div>
        </div>
        <div :if={@body_weight}>
          <div class="row" style="gap:8px;align-items:baseline">
            <div class="big">
              {format_number(@body_weight["w"])} <span class="muted body-unit">{@state["unit"]}</span>
            </div>
            <span
              :if={@delta && abs(@delta) >= 0.05}
              class={[
                "small",
                "row",
                weight_delta_class(@delta, @body_weight["w"], @state["targetW"])
              ]}
              style="gap:2px;font-weight:500"
            >
              <.icon name={if @delta > 0, do: "hero-arrow-up", else: "hero-arrow-down"} />
              {format_number(abs(@delta))}
            </span>
            <span class="dim small" style="margin-left:auto">{short_date_label(
              @locale,
              @body_weight["d"]
            )}</span>
          </div>
          <div :if={@state["targetW"]} class="small row home-goal-progress">
            <.icon name="hero-target" /><span>{goal_progress_label(
              @locale,
              @state["targetW"],
              @body_weight["w"],
              @state["unit"]
            )}</span>
          </div>
          <.weight_chart
            id="home-weight-chart"
            rows={@state["bodyweight"]}
            goal={@state["targetW"]}
            unit={@state["unit"]}
            locale={@locale}
          />
        </div>
        <div :if={is_nil(@body_weight)} class="muted small">
          {t(@locale, "No entries yet — log your weight to start the curve.")}
        </div>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :ai_configured, :boolean, required: true

  def plan(assigns) do
    assigns = assign(assigns, :days, days(assigns.locale))

    ~H"""
    <div class="narrow">
      <header class="hdr">
        <div>
          <h1>{t(@locale, "Plan")}</h1><div class="sub">{t(@locale, "Weekly schedule")}</div>
        </div>
      </header>
      <div :if={@ai_configured} class="card ai-plan-card">
        <div class="row" style="align-items:flex-start;margin-bottom:12px">
          <span class="lrow-i" style="--tint:var(--purple)"><.icon name="hero-sparkles" /></span>
          <div class="grow">
            <div class="tt">{t(@locale, "AI planner")}</div>
            <div class="muted small">
              {t(
                @locale,
                "Generate a complete commercial-gym split from today, including recovery days."
              )}
            </div>
          </div>
        </div>
        <button class="btn tinted" phx-click="ai:week-open">
          <.icon name="hero-sparkles" />{t(@locale, "Plan my next 7 days")}
        </button>
      </div>
      <div class="cols">
        <section>
          <h4 class="sec">{t(@locale, "Weekly schedule")}</h4>
          <div class="list schedule-list">
            <button
              :for={{day_name, day} <- @days}
              class="item schedule-item"
              phx-click="schedule:open"
              phx-value-day={day}
            >
              <div class="schedule-copy">
                <div class="schedule-day">{day_name}</div>
                <div :if={routine = routine_for_day(@state, day)} class="schedule-assignment">
                  <.icon name="hero-dumbbell" />
                  <span>{routine["name"]}</span>
                </div>
                <div
                  :if={is_nil(routine_for_day(@state, day))}
                  class="schedule-assignment rest"
                >
                  <.icon name="hero-moon" />
                  <span>{t(@locale, "Rest")}</span>
                </div>
              </div>
              <.icon name="hero-chevron-right" class="chev" />
            </button>
          </div>
        </section>
        <section>
          <div class="row between" style="margin:22px 0 10px">
            <h4 class="sec" style="margin:0">{t(@locale, "Routines")}</h4>
            <button class="btn tinted sm" phx-click="routine:new"><.icon name="hero-plus" />{t(
              @locale,
              "New routine"
            )}</button>
          </div>
          <div :if={@state["routines"] != []} class="list">
            <.link
              :for={routine <- @state["routines"]}
              navigate={~p"/plan/r/#{routine["id"]}"}
              class="item"
            >
              <span class="lrow-i"><.icon name="hero-dumbbell" /></span><div class="grow">
                <div class="tt">{routine["name"]}</div><div class="ss">
                  {length(routine["ex"])} {t(@locale, "Exercises")}
                </div>
              </div><.icon name="hero-chevron-right" class="chev" />
            </.link>
          </div>
          <div :if={@state["routines"] == []} class="empty">
            <div class="ico"><.icon name="hero-dumbbell" /></div>{t(@locale, "No routines yet.")}
          </div>
        </section>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :routine_id, :string, required: true

  def routine(assigns) do
    routine = Enum.find(assigns.state["routines"], &(&1["id"] == assigns.routine_id))
    load = if routine, do: BodyMap.routine_load(assigns.state, routine), else: %{}
    assigns = assign(assigns, routine: routine, muscle_load: load)

    ~H"""
    <div class="narrow">
      <header class="hdr">
        <.link patch={~p"/plan"} class="iconbtn"><.icon name="hero-arrow-left" /></.link><div style="flex:1">
          <h1>{(@routine && @routine["name"]) || t(@locale, "New routine")}</h1>
        </div>
      </header>
      <div :if={@routine}>
        <.form
          for={to_form(%{"name" => @routine["name"], "emoji" => @routine["emoji"] || "dumbbell"})}
          id="routine-form"
          phx-change="routine:update"
          class="card lv-form"
        >
          <.input
            name="name"
            value={@routine["name"]}
            label={t(@locale, "Name")}
            phx-debounce="400"
            required
          />
          <input type="hidden" name="emoji" value="dumbbell" />
        </.form>
        <h4 class="sec">{t(@locale, "Exercises")}</h4>
        <div :if={@routine["ex"] != []} class="list routine-plan-list">
          <button
            :for={{config, index} <- Enum.with_index(@routine["ex"])}
            class="item routine-plan-row"
            phx-click="routine:exercise-open"
            phx-value-index={index}
          >
            <img class="thumb" src={exercise_thumbnail(@state, config["id"])} loading="lazy" alt="" /><div
              class="grow"
              style="text-align:left"
            >
              <div class="tt capitalize">{exercise_name(@state, config["id"])}</div><div class="ss">
                {routine_config_label(@state, config, @locale)}
              </div>
            </div><.icon name="hero-chevron-right" class="chev" />
          </button>
        </div>
        <div :if={@routine["ex"] == []} class="empty">
          <div class="ico"><.icon name="hero-dumbbell" /></div>{t(
            @locale,
            "No exercises yet — add your first one."
          )}
        </div>

        <div :if={@routine["ex"] != []} class="card routine-muscle-card">
          <h2>{t(@locale, "What this session hits")}</h2>
          <.muscle_map load={@muscle_load} body={@state["body"]} locale={@locale} />
        </div>

        <button class="btn primary routine-add-exercise" phx-click="routine:exercise-picker"><.icon name="hero-plus" />{t(
          @locale,
          "Add exercise"
        )}</button>
        <div style="height:10px"></div><.button
          class="btn danger"
          icon="hero-trash"
          phx-click="routine:delete"
          phx-value-id={@routine["id"]}
        >{t(@locale, "Delete")}</.button>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :search, :string, required: true
  attr :results, :list, required: true
  attr :ai_configured, :boolean, required: true

  def workout(assigns) do
    active = assigns.state["active"]
    entries = (active && active["entries"]) || []
    current_index = (active && min(active["cur"] || 0, max(length(entries) - 1, 0))) || 0
    current = Enum.at(entries, current_index)
    total = Enum.reduce(entries, 0, &(&2 + length(&1["sets"])))
    done = entries |> Enum.flat_map(& &1["sets"]) |> Enum.count(& &1["done"])
    exercise = current && exercise(assigns.state, current["id"])
    target = (current && current["target"]) || %{}
    bodyweight_movement = exercise && (target["bodyweight"] || exercise["eq"] == "body weight")

    bodyweight_exercise =
      bodyweight_movement && Enum.all?(current["sets"], &(State.number(&1["w"]) <= 0))

    last_entry = current && last_exercise_entry(assigns.state, current["id"])
    today_routine = State.effective_routine(assigns.state)

    assigns =
      assign(assigns,
        active: active,
        entries: entries,
        current: current,
        current_index: current_index,
        total: total,
        done: done,
        exercise: exercise,
        bodyweight_movement: bodyweight_movement,
        bodyweight_exercise: bodyweight_exercise,
        last_entry: last_entry,
        today_routine: today_routine
      )

    ~H"""
    <div class="narrow" id="workout-screen">
      <div :if={is_nil(@active)}>
        <header class="hdr">
          <div>
            <h1>{t(@locale, "Start workout")}</h1><div class="sub">
              {date_label(@locale, Date.utc_today())}
            </div>
          </div>
        </header>
        <div :if={@today_routine} class="card" style="border:1px solid var(--acc)">
          <h2 class="accent">{t(@locale, "Today")}</h2>
          <div class="row between" style="margin-bottom:12px">
            <div>
              <div class="big">{@today_routine["name"]}</div><div class="muted small">
                {length(@today_routine["ex"])} {t(@locale, "Exercises")}
              </div>
            </div><span class="lrow-i"><.icon name="hero-dumbbell" /></span>
          </div>
          <button class="btn primary" phx-click="workout:prepare" phx-value-id={@today_routine["id"]}><.icon name="hero-play" />{t(
            @locale,
            "Start"
          )} {@today_routine["name"]}</button>
        </div>
        <h4 :if={@state["routines"] != []} class="sec">{t(@locale, "Routines")}</h4>
        <div class="list">
          <button
            :for={routine <- @state["routines"]}
            :if={is_nil(@today_routine) || routine["id"] != @today_routine["id"]}
            class="item"
            phx-click="workout:prepare"
            phx-value-id={routine["id"]}
          >
            <span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
              class="grow"
              style="text-align:left"
            >
              <div class="tt">{routine["name"]}</div><div class="ss">
                {length(routine["ex"])} {t(@locale, "Exercises")}
              </div>
            </div><span class="tag acc">{t(@locale, "Start")}</span>
          </button>
        </div>
        <div style="height:14px"></div>
        <button class="btn" phx-click="workout:prepare" phx-value-id="freestyle"><.icon name="hero-shuffle" />{t(
          @locale,
          "Freestyle workout"
        )}</button>
      </div>

      <div :if={@active}>
        <header class="hdr workout-header">
          <button class="iconbtn" aria-label={t(@locale, "Discard")} phx-click="workout:cancel-open"><.icon name="hero-x-mark" /></button>
          <div style="text-align:center">
            <div style="font-weight:600">{@active["name"]}</div><div class="sub">
              <span id="elapsed" phx-hook="Elapsed" data-started-at={@active["start"]}>0:00</span>
              · {@done}/{@total} {t(@locale, "sets")}
            </div>
          </div>
          <button
            class="iconbtn accent"
            aria-label={t(@locale, "Finish")}
            phx-click="workout:finish-open"
          ><.icon name="hero-check" /></button>
        </header>
        <div class="wprog">
          <i style={"width:#{if @total > 0, do: round(@done / @total * 100), else: 0}%"}></i>
        </div>

        <div :if={@current && @exercise}>
          <div class="muted small" style="margin-bottom:6px">
            {t(@locale, "Exercise")} {@current_index + 1} / {length(@entries)}
          </div>
          <.exercise_media exercise={@exercise} locale={@locale} compact={false} />
          <div class="row between" style="margin-bottom:6px">
            <div class="exercise-title capitalize">{@exercise["n"]}</div>
            <button
              class="iconbtn"
              phx-click="exercise:open"
              phx-value-id={@exercise["id"]}
              aria-label="Details"
            ><.icon name="hero-information-circle" /></button>
          </div>
          <div class="row exercise-tags">
            <span class="tag acc">{@exercise["tg"] || @exercise["bp"]}</span><span class="tag">{@exercise[
              "eq"
            ]}</span>
            <span :if={@bodyweight_movement && @active["bw"]} class="tag nocap">{format_number(
              @active["bw"]
            )} {@state["unit"]} {t(@locale, "body weight")}</span>
            <span :if={best_weight(@state, @exercise["id"]) > 0} class="tag nocap">{t(@locale, "Best")}: {format_number(
              best_weight(@state, @exercise["id"])
            )} {@state["unit"]}</span>
          </div>
          <div :if={@last_entry} class="small dim workout-last">
            {t(@locale, "Last time")} ({@last_entry.date}): {@last_entry.label}
          </div>

          <div class="card workout-sets">
            <div class={["sethead", "live", @bodyweight_exercise && "bodyweight"]}>
              <span class="n-sp"></span><span :if={!@bodyweight_exercise} class="w-sp">{t(
                @locale,
                if(@bodyweight_movement, do: "added", else: "weight")
              )} ({@state["unit"]})</span><span class="r-sp">{t(@locale, "reps")}</span><span class="ck-sp"></span>
            </div>
            <div :for={{set, set_index} <- Enum.with_index(@current["sets"])} class="set-block">
              <div
                :if={State.warmup_set?(set) && starts_phase?(@current["sets"], set_index, true)}
                class="setph"
              >
                {t(@locale, "Warm-up")}
              </div>
              <div
                :if={
                  !State.warmup_set?(set) && starts_phase?(@current["sets"], set_index, false) &&
                    set_index > 0
                }
                class="setsep"
              >
              </div>
              <.form
                for={to_form(%{})}
                id={"set-#{@current_index}-#{set_index}"}
                phx-change="set:update"
                class={[
                  "setrow",
                  "live-step-row",
                  @bodyweight_exercise && "bodyweight",
                  State.warmup_set?(set) && "warmup",
                  set["done"] && "done"
                ]}
              >
                <input type="hidden" name="entry" value={@current_index} /><input
                  type="hidden"
                  name="set"
                  value={set_index}
                />
                <div class="n">{phase_number(@current["sets"], set_index)}</div>
                <div :if={!@bodyweight_exercise} class="stp w">
                  <button
                    type="button"
                    aria-label={t(@locale, "Decrease weight")}
                    phx-click="set:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-field="w"
                    phx-value-direction="down"
                  ><.icon name="hero-minus" /></button>
                  <span class="val"><.input
                    class="num"
                    name="w"
                    type="number"
                    value={set["w"] || 0}
                    min="0"
                    step="0.5"
                    inputmode="decimal"
                  /></span>
                  <button
                    type="button"
                    aria-label={t(@locale, "Increase weight")}
                    phx-click="set:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-field="w"
                    phx-value-direction="up"
                  ><.icon name="hero-plus" /></button>
                </div>
                <div class="stp r">
                  <button
                    type="button"
                    aria-label={t(@locale, "Decrease reps")}
                    phx-click="set:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-field="r"
                    phx-value-direction="down"
                  ><.icon name="hero-minus" /></button>
                  <span class="val"><.input
                    class="num"
                    name="r"
                    type="number"
                    value={set["r"] || 0}
                    min="0"
                    step="1"
                    inputmode="numeric"
                  /></span>
                  <button
                    type="button"
                    aria-label={t(@locale, "Increase reps")}
                    phx-click="set:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-field="r"
                    phx-value-direction="up"
                  ><.icon name="hero-plus" /></button>
                </div>
                <button
                  type="button"
                  class={["chk", set["done"] && "on"]}
                  phx-click="set:toggle"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                  aria-label={t(@locale, "Done")}
                ><.icon name="hero-check" /></button>
              </.form>

              <div
                :for={{drop, drop_index} <- Enum.with_index(List.wrap(set["drops"]))}
                class="subrow drop-row"
              >
                <span class="subn">{t(@locale, "Drop")} {drop_index + 1}</span>
                <div class="stp mini">
                  <button
                    type="button"
                    aria-label={t(@locale, "Decrease weight")}
                    phx-click="drop:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-drop={drop_index}
                    phx-value-field="w"
                    phx-value-direction="down"
                  ><.icon name="hero-minus" /></button><span class="val burst-value">{format_number(
                    drop["w"]
                  )}</span><button
                    type="button"
                    aria-label={t(@locale, "Increase weight")}
                    phx-click="drop:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-drop={drop_index}
                    phx-value-field="w"
                    phx-value-direction="up"
                  ><.icon name="hero-plus" /></button>
                </div>
                <div class="stp mini">
                  <button
                    type="button"
                    aria-label={t(@locale, "Decrease reps")}
                    phx-click="drop:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-drop={drop_index}
                    phx-value-field="r"
                    phx-value-direction="down"
                  ><.icon name="hero-minus" /></button><span class="val burst-value">{drop["r"]}</span><button
                    type="button"
                    aria-label={t(@locale, "Increase reps")}
                    phx-click="drop:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-drop={drop_index}
                    phx-value-field="r"
                    phx-value-direction="up"
                  ><.icon name="hero-plus" /></button>
                </div>
                <button
                  type="button"
                  class="iconbtn"
                  aria-label={t(@locale, "Remove drop")}
                  phx-click="drop:remove"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                  phx-value-drop={drop_index}
                ><.icon name="hero-x-mark" /></button>
              </div>

              <div
                :for={{burst, burst_index} <- Enum.with_index(List.wrap(set["clusters"]))}
                class="subrow burst-row"
              >
                <span class="subn">{t(@locale, "Burst")} {burst_index + 1}</span>
                <div class="stp mini">
                  <button
                    type="button"
                    aria-label={t(@locale, "Decrease reps")}
                    phx-click="burst:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-burst={burst_index}
                    phx-value-direction="down"
                  ><.icon name="hero-minus" /></button><span class="val burst-value">{burst["r"]}</span><button
                    type="button"
                    aria-label={t(@locale, "Increase reps")}
                    phx-click="burst:step"
                    phx-value-entry={@current_index}
                    phx-value-set={set_index}
                    phx-value-burst={burst_index}
                    phx-value-direction="up"
                  ><.icon name="hero-plus" /></button>
                </div>
                <button
                  type="button"
                  class="burst-rest"
                  phx-click="rest:start"
                  phx-value-seconds={burst["restSec"]}
                >{burst["restSec"]}s</button>
                <button
                  type="button"
                  class="iconbtn"
                  aria-label={t(@locale, "Remove burst")}
                  phx-click="burst:remove"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                  phx-value-burst={burst_index}
                ><.icon name="hero-x-mark" /></button>
              </div>

              <div :if={State.warmup_set?(set)} class="setextra">
                <button
                  type="button"
                  class="chip warm-remove"
                  phx-click="set:remove"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                ><.icon name="hero-x-mark" />{t(@locale, "Remove warm-up")}</button>
              </div>
              <div :if={!State.warmup_set?(set)} class="setextra">
                <button
                  :if={!@bodyweight_exercise && List.wrap(set["clusters"]) == []}
                  type="button"
                  class="chip add"
                  phx-click="drop:add"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                ><.icon name="hero-arrow-down" />+ {t(@locale, "Drop")}</button>
                <button
                  :if={List.wrap(set["drops"]) == []}
                  type="button"
                  class="chip add"
                  phx-click="burst:add"
                  phx-value-entry={@current_index}
                  phx-value-set={set_index}
                ><.icon name="hero-bolt" />+ {t(@locale, "Burst")}</button>
              </div>
            </div>
            <div class="row set-actions">
              <button class="btn sm" phx-click="set:add-warmup" phx-value-entry={@current_index}><.icon name="hero-fire" />{t(
                @locale,
                "Add warm-up set"
              )}</button>
              <button
                class="btn sm"
                phx-click="set:remove"
                phx-value-entry={@current_index}
                phx-value-set={length(@current["sets"]) - 1}
                disabled={Enum.count(@current["sets"], &(not State.warmup_set?(&1))) <= 1}
              ><.icon name="hero-minus" />{t(@locale, "Remove set")}</button>
              <button class="btn sm tinted" phx-click="set:add" phx-value-entry={@current_index}><.icon name="hero-plus" />{t(
                @locale,
                "Add set"
              )}</button>
            </div>
          </div>
        </div>

        <div :if={@entries == []} class="empty">
          <div class="ico"><.icon name="hero-shuffle" /></div>{t(
            @locale,
            "Freestyle workout — add your first exercise."
          )}
        </div>
        <div :if={@entries != []} class="row workout-navigation">
          <button
            class="btn"
            phx-click="workout:move"
            phx-value-direction="previous"
            disabled={@current_index <= 0}
          ><.icon name="hero-chevron-left" />{t(@locale, "Prev")}</button>
          <button
            class="btn"
            phx-click="workout:move"
            phx-value-direction="next"
            disabled={@current_index >= length(@entries) - 1}
          >{t(@locale, "Next")}<.icon name="hero-chevron-right" /></button>
        </div>

        <button class="btn workout-add-exercise" phx-click="workout:exercise-picker"><.icon name="hero-plus" />{t(
          @locale,
          "Add exercise"
        )}</button>

        <div :if={@current} class="workout-exercise-actions">
          <div class="row">
            <button
              class="btn sm"
              phx-click="workout:reorder"
              phx-value-direction="up"
              disabled={@current_index <= 0}
            ><.icon name="hero-chevron-up" />{t(@locale, "Move up")}</button>
            <button
              class="btn sm"
              phx-click="workout:reorder"
              phx-value-direction="down"
              disabled={@current_index >= length(@entries) - 1}
            >{t(@locale, "Move down")}<.icon name="hero-chevron-down" /></button>
          </div>
          <button class="btn sm" phx-click="workout:swap-open" phx-value-index={@current_index}><.icon name="hero-arrow-path" />{t(
            @locale,
            "Swap exercise"
          )}</button>
          <button
            :if={@ai_configured}
            class="btn sm tinted"
            phx-click="ai:alternatives-open"
            phx-value-index={@current_index}
          ><.icon name="hero-sparkles" />{t(@locale, "Find alternatives with AI")}</button>
          <button
            class="btn sm remove-exercise"
            phx-click="workout:remove-open"
            phx-value-index={@current_index}
          ><.icon name="hero-minus" />{t(@locale, "Remove exercise")}</button>
        </div>

        <button
          class={
            if @total > 0 && @done == @total,
              do: "btn primary workout-finish",
              else: "btn ghost workout-finish"
          }
          phx-click="workout:finish-open"
        >{t(@locale, "Finish workout")} · {@done}/{@total}</button>

        <div
          id="timer"
          class="rest"
          phx-hook="RestTimer"
          phx-update="ignore"
          role="timer"
          aria-label={t(@locale, "Rest timer")}
          hidden
        >
          <div class="head">
            <div class="t" data-rest-time>0:00</div><div class="bar">
              <i data-rest-progress style="width:100%"></i>
            </div>
          </div>
          <div class="acts">
            <button type="button" class="btn sm" data-rest-adjust="-15"><.icon name="hero-minus" />15s</button><button
              type="button"
              class="btn sm"
              data-rest-adjust="15"
            ><.icon name="hero-plus" />15s</button><button
              type="button"
              class="btn primary sm skip"
              data-rest-skip
            >{t(@locale, "Skip")}</button>
          </div>
        </div>

        <div style="height:40px"></div>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :range, :integer, required: true
  attr :selected_exercise, :string, default: nil

  def stats(assigns) do
    today = Date.utc_today()
    summary = State.stats(assigns.state)
    bodyweight = weight_in_range(assigns.state["bodyweight"], assigns.range, today)
    month = Calendar.strftime(today, "%Y-%m")

    month_workouts =
      Enum.count(assigns.state["workouts"], &String.starts_with?(&1["d"] || "", month))

    exercise_ids = stats_exercise_ids(assigns.state)

    selected_exercise =
      if assigns.selected_exercise in exercise_ids,
        do: assigns.selected_exercise,
        else: List.first(exercise_ids)

    progress = exercise_progress(assigns.state, selected_exercise)

    assigns =
      assign(assigns,
        summary: summary,
        bodyweight: bodyweight,
        month_workouts: month_workouts,
        streak: streak_weeks(assigns.state),
        weight_delta: weight_delta(assigns.state["bodyweight"], today),
        activity: activity_days(assigns.state, today),
        muscles: muscle_balance(assigns.state, today),
        exercise_ids: exercise_ids,
        selected_exercise: selected_exercise,
        selected: selected_exercise && exercise(assigns.state, selected_exercise),
        progress: progress,
        progress_rows: Enum.map(progress, &%{"w" => &1.value, "d" => &1.date}),
        progress_unit:
          (List.first(progress) && List.first(progress).unit) || assigns.state["unit"],
        progress_best: progress |> Enum.map(& &1.value) |> Enum.max(fn -> 0.0 end)
      )

    ~H"""
    <div class="stats-page">
      <header class="hdr">
        <div>
          <h1>{t(@locale, "Stats")}</h1><div class="sub">{t(@locale, "Progress & history")}</div>
        </div>
        <button
          class="iconbtn"
          phx-click="nav"
          phx-value-to="/history"
          aria-label={t(@locale, "History")}
        ><.icon name="hero-clock" /></button>
      </header>

      <div class="tiles stats-tiles">
        <div class="tile">
          <div class="l"><.icon name="hero-dumbbell" />{t(@locale, "Workouts")}</div><div class="v">
            {@summary.workouts}
          </div>
        </div>
        <div class="tile">
          <div class="l"><.icon name="hero-calendar-days" />{t(@locale, "This month")}</div><div class="v">
            {@month_workouts}
          </div>
        </div>
        <div class="tile">
          <div class="l"><.icon name="hero-fire" />{t(@locale, "Week streak")}</div><div class="v">
            {@streak}
          </div>
        </div>
        <div class="tile">
          <div class="l"><.icon name="hero-scale" />{t(@locale, "Weight 30d")}</div><div
            class={[
              "v",
              @weight_delta && @weight_delta > 0 && "weight-up",
              @weight_delta && @weight_delta < 0 && "weight-down"
            ]}
            style="font-size:22px"
          >
            {if is_nil(@weight_delta), do: "—", else: signed_number(@weight_delta)}<span
              :if={not is_nil(@weight_delta)}
              class="small"
            >{@state["unit"]}</span>
          </div>
        </div>
      </div>

      <div class="card">
        <h2>
          {t(@locale, "Activity — last 12 months")}
          <span class="dim normal-title">· {t(@locale, "by workouts")}</span>
        </h2>
        <div id="activity-scroll" class="activity-scroll" phx-hook="ScrollEnd">
          <div class="activity-heatmap" aria-label={t(@locale, "Workout activity")}>
            <button
              :for={day <- @activity}
              type="button"
              class={"activity-cell l#{day.level}"}
              title={"#{day.date}: #{day.count}"}
              aria-label={"#{day.date}: #{day.count} #{t(@locale, "Workouts")}"}
              phx-click={if day.count > 0, do: "activity:open"}
              phx-value-date={day.date}
              disabled={day.count == 0}
            ></button>
          </div>
        </div>
        <div class="activity-legend">
          <span>{t(@locale, "Less")}</span><i class="l0"></i><i class="l1"></i><i class="l2"></i><i class="l3"></i><i class="l4"></i><span>{t(
            @locale,
            "More"
          )}</span>
        </div>
      </div>

      <div :if={@summary.workouts > 0} class="card muscle-card">
        <h2>
          {t(@locale, "Muscle balance")}
          <span class="dim normal-title">· {t(@locale, "by completed sets, 30d")}</span>
        </h2>
        <div :if={@muscles == []} class="muted small">
          {t(@locale, "No completed sets in this period.")}
        </div>
        <div :for={muscle <- @muscles} class="mrow">
          <span class="nm capitalize">{muscle.name}</span><span class="bar"><i style={"width:#{muscle.percent}%"}></i></span><span class="v">{muscle.sets} {t(
            @locale,
            "sets"
          )}</span>
        </div>
      </div>

      <div class="cols stats-cols">
        <div class="card">
          <div class="row between" style="margin-bottom:8px">
            <h2 style="margin:0">{t(@locale, "Body weight")}</h2><div class="row stats-actions">
              <button class="btn sm" phx-click="goal:open"><.icon name="hero-target" />{if @state[
                                                                                             "targetW"
                                                                                           ],
                                                                                           do:
                                                                                             format_number(
                                                                                               @state[
                                                                                                 "targetW"
                                                                                               ]
                                                                                             ),
                                                                                           else:
                                                                                             t(
                                                                                               @locale,
                                                                                               "Goal"
                                                                                             )}</button><button
                class="btn sm"
                phx-click="bodyweight:open"
              ><.icon name="hero-plus" />{t(@locale, "Log")}</button>
            </div>
          </div>
          <div class="seg seg-range">
            <button
              :for={{days, label} <- [{30, "1M"}, {90, "3M"}, {365, "1Y"}, {0, t(@locale, "All")}]}
              class={if @range == days, do: "on"}
              phx-click="stats:range"
              phx-value-days={days}
            >{label}</button>
          </div>
          <.weight_chart
            id="stats-weight-chart"
            rows={@bodyweight}
            goal={@state["targetW"]}
            unit={@state["unit"]}
            locale={@locale}
          />
          <div :if={@bodyweight == []} class="empty compact">
            {t(@locale, "Log your body weight to see progress here.")}
          </div>
        </div>

        <div class="card">
          <h2>{t(@locale, "Exercise progress")}</h2>
          <button :if={@selected} class="selectrow" phx-click="stats:exercise-open"><span><span class="small dim">{t(
            @locale,
            "Exercise"
          )}</span><b class="capitalize">{@selected["n"]}</b></span><span class="row"><span
            :if={@progress_best > 0}
            class="accent"
          >{format_number(@progress_best)} {@progress_unit}</span><.icon name="hero-chevron-right" /></span></button>
          <.weight_chart
            :if={@progress != []}
            id="stats-progress-chart"
            rows={@progress_rows}
            unit={@progress_unit}
            locale={@locale}
          />
          <div :if={@progress != []} class="progress-list">
            <div :for={point <- @progress |> Enum.reverse() |> Enum.take(5)} class="row between small">
              <span class="muted">{point.date}</span><b>{format_number(point.value)} {point.unit}</b>
            </div>
          </div>
          <div :if={@progress == []} class="muted small">
            {t(@locale, "Finish your first workout to see progress curves here.")}
          </div>
          <div :if={@progress_best > 0} class="small dim" style="margin-top:8px">
            {t(@locale, "Best:")}
            <b class="accent">{format_number(@progress_best)} {@progress_unit}</b>
          </div>
        </div>
      </div>

      <div :if={@state["workouts"] != []}>
        <div class="row between" style="margin-bottom:10px">
          <h4 class="sec" style="margin:0">{t(@locale, "Recent workouts")}</h4><button
            class="btn ghost sm"
            phx-click="nav"
            phx-value-to="/history"
          >{t(@locale, "All")} {length(@state["workouts"])}<.icon name="hero-chevron-right" /></button>
        </div>
        <div class="list">
          <button
            :for={workout <- @state["workouts"] |> Enum.reverse() |> Enum.take(6)}
            class="item"
            phx-click="workout:open"
            phx-value-id={workout["id"]}
          ><span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
            class="grow"
            style="text-align:left"
          >
            <div class="tt">{workout["name"] || t(@locale, "Workout")}</div><div class="ss">
              {workout["d"]} · {length(workout["entries"])} {t(@locale, "Exercises")} · {format_number(
                workout["vol"] || State.workout_volume(workout)
              )} {@state["unit"]}
            </div>
          </div><.icon name="hero-chevron-right" class="chev" /></button>
        </div>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true

  def history(assigns) do
    ~H"""
    <div class="narrow">
      <header class="hdr">
        <div>
          <h1>{t(@locale, "History")}</h1>
        </div>
      </header>
      <div :if={@state["workouts"] == []} class="empty">{t(@locale, "No workouts yet.")}</div>
      <div class="list">
        <article
          :for={workout <- Enum.reverse(@state["workouts"])}
          class="item"
          style="align-items:flex-start"
        >
          <span class="lrow-i"><.icon name="hero-clock" /></span><div class="grow">
            <div class="tt">{workout["name"] || t(@locale, "Workout")}</div><div class="ss">
              {workout["d"]} · {format_number(workout["vol"] || State.workout_volume(workout))} {@state[
                "unit"
              ]}
            </div><div class="lv-history-ex">
              {Enum.map_join(workout["entries"], ", ", &exercise_name(@state, &1["id"]))}
            </div>
          </div><button class="iconbtn" phx-click="workout:delete" phx-value-id={workout["id"]}><.icon name="hero-trash" /></button>
        </article>
      </div>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :search, :string, required: true
  attr :results, :list, required: true
  attr :body_part, :string, required: true
  attr :equipment, :string, required: true

  def library(assigns) do
    body_parts = Catalogue.all() |> Enum.map(& &1["bp"]) |> Enum.uniq() |> Enum.sort()
    equipment_options = catalogue_equipment(assigns.search, assigns.body_part)
    assigns = assign(assigns, body_parts: body_parts, equipment_options: equipment_options)

    ~H"""
    <div class="narrow">
      <header class="hdr">
        <div>
          <h1>{t(@locale, "Exercises")}</h1>
          <div class="sub">{length(Catalogue.all())} {t(@locale, "exercises with animations")}</div>
        </div>
      </header>

      <.search_box locale={@locale} search={@search} />
      <div class="chips" style="margin-bottom:8px">
        <button
          class={["chip", "nocap", @body_part == "" && "on"]}
          phx-click="filter:bodypart"
          phx-value-value=""
        >{t(@locale, "All")}</button>
        <button
          :for={body_part <- @body_parts}
          class={["chip", @body_part == body_part && "on"]}
          phx-click="filter:bodypart"
          phx-value-value={body_part}
        >{body_part}</button>
      </div>
      <div class="chips" style="margin-bottom:12px">
        <button
          class={["chip", "nocap", @equipment == "" && "on"]}
          phx-click="filter:equipment"
          phx-value-value=""
        >{t(@locale, "Any equipment")}</button>
        <button
          :for={equipment <- @equipment_options}
          class={["chip", @equipment == equipment && "on"]}
          phx-click="filter:equipment"
          phx-value-value={equipment}
        >{equipment}</button>
      </div>

      <div class="list">
        <button class="item" phx-click="custom:open">
          <div class="thumb thumb-x"><.icon name="hero-sparkles" /></div>
          <div class="grow">
            <div class="tt">{t(@locale, "Create your own exercise")}</div><div class="ss">
              {t(@locale, "name + body part, no animation")}
            </div>
          </div>
          <.icon name="hero-plus" class="chev" />
        </button>

        <div :for={exercise <- @state["customEx"]} class="item">
          <button class="library-main" phx-click="exercise:open" phx-value-id={exercise["id"]}>
            <div class="thumb thumb-x"><.icon name="hero-dumbbell" /></div>
            <div class="grow">
              <div class="tt capitalize">{exercise["n"]}</div><div class="ss capitalize">
                {exercise["bp"]} · {exercise["eq"]}
              </div>
            </div>
          </button>
          <button class="btn sm tinted" phx-click="exercise:add-plan" phx-value-id={exercise["id"]}><.icon name="hero-plus" />{t(
            @locale,
            "Plan"
          )}</button>
        </div>

        <div :for={exercise <- @results} class="item">
          <button class="library-main" phx-click="exercise:open" phx-value-id={exercise["id"]}>
            <img class="thumb" src={~p"/img/#{exercise["img"]}"} loading="lazy" alt="" />
            <div class="grow">
              <div class="tt capitalize">{exercise["n"]}</div><div class="ss capitalize">
                {exercise["tg"] || exercise["bp"]} · {exercise["eq"]}
              </div>
            </div>
          </button>
          <span :if={best_weight(@state, exercise["id"]) > 0} class="tag acc">{format_number(
            best_weight(@state, exercise["id"])
          )}</span>
          <button class="btn sm tinted" phx-click="exercise:add-plan" phx-value-id={exercise["id"]}><.icon name="hero-plus" />{t(
            @locale,
            "Plan"
          )}</button>
        </div>
      </div>

      <div :if={@results == []} class="empty">
        <div class="ico"><.icon name="hero-magnifying-glass" /></div>{t(@locale, "No match")}
      </div>
      <button
        :if={length(@results) >= 40}
        class="btn"
        style="margin-top:10px"
        phx-click="catalogue:more"
      >{t(@locale, "Show more")}</button>
    </div>
    """
  end

  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :current_scope, :map, required: true
  attr :ai_models, :list, required: true

  def settings(assigns) do
    local_only = assigns.current_scope.local_only?

    assigns =
      assign(assigns,
        local_only: local_only,
        accents: accent_options(),
        language_name: language_name(assigns.state["lang"], assigns.locale),
        ai_model: AI.selected_model(assigns.state)
      )

    ~H"""
    <div class="narrow settings-page">
      <header class="hdr settings-header">
        <button class="iconbtn" phx-click="nav" phx-value-to="/home" aria-label={t(@locale, "Home")}><.icon name="hero-chevron-left" /></button>
        <div>
          <h1>{t(@locale, "Settings")}</h1>
        </div>
      </header>

      <section class="sect">
        <span class="sect-t">{t(@locale, "Account")}</span>
        <div class="sect-b">
          <div class="lrow">
            <span class="lrow-i" style="--tint:var(--grey)"><.icon name="hero-user-circle" /></span>
            <span class="lrow-m"><span class="lrow-t">{if @local_only,
              do: t(@locale, "Using without an account"),
              else: @current_scope.user.email}</span><span class="lrow-s">{if @local_only,
              do: t(@locale, "Saved only in this browser."),
              else: t(@locale, "Plans and workout data are saved in SQLite.")}</span></span>
            <span :if={@local_only} class="lv-local-badge">{t(@locale, "Local only")}</span>
          </div>
          <button :if={@local_only} class="lrow tap" phx-click="guest:leave">
            <span class="lrow-i" style="--tint:var(--blue)"><.icon name="hero-user-circle" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Sign in or create an account"
            )}</span></span><.icon name="hero-chevron-right" class="lrow-c" />
          </button>
          <button :if={!@local_only} class="lrow tap danger" phx-click="account:signout-open">
            <span class="lrow-i" style="--tint:var(--red)"><.icon name="hero-arrow-right-start-on-rectangle" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Sign out"
            )}</span></span>
          </button>
        </div>
      </section>

      <section class="sect">
        <span class="sect-t">{t(@locale, "General")}</span>
        <div class="sect-b">
          <button
            id="language-preference"
            class="lrow tap"
            phx-click="setting:open"
            phx-value-key="lang"
          >
            <span class="lrow-i" style="--tint:var(--blue)"><.icon name="hero-globe-alt" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Language"
            )}</span></span><span class="lrow-v">{@language_name}</span><.icon
              name="hero-chevron-right"
              class="lrow-c"
            />
          </button>
          <div class="lrow">
            <span class="lrow-i" style="--tint:var(--teal)"><.icon name="hero-scale" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Weight unit"
            )}</span></span>
            <div class="seg seg-inline">
              <button
                class={if @state["unit"] == "kg", do: "on"}
                phx-click="setting:set"
                phx-value-key="unit"
                phx-value-setting="kg"
              >kg</button><button
                class={if @state["unit"] == "lb", do: "on"}
                phx-click="setting:set"
                phx-value-key="unit"
                phx-value-setting="lb"
              >lb</button>
            </div>
          </div>
        </div>
        <div class="sect-f">
          {t(
            @locale,
            "Note: switching units only changes the label — logged numbers are not converted."
          )}
        </div>
      </section>

      <section :if={@ai_models != []} class="sect">
        <span class="sect-t">{t(@locale, "AI planner")}</span>
        <div class="sect-b">
          <button class="lrow tap" phx-click="ai:model-open">
            <span class="lrow-i" style="--tint:var(--purple)"><.icon name="hero-sparkles" /></span>
            <span class="lrow-m"><span class="lrow-t">{t(@locale, "AI model")}</span></span>
            <span class="lrow-v">{@ai_model}</span>
            <.icon name="hero-chevron-right" class="lrow-c" />
          </button>
        </div>
        <div class="sect-f">
          {t(@locale, "Your selected model is saved per account or browser.")}
        </div>
      </section>

      <section class="sect">
        <span class="sect-t">{t(@locale, "During a workout")}</span>
        <div class="sect-b">
          <button class="lrow tap" phx-click="setting:open" phx-value-key="restSec">
            <span class="lrow-i" style="--tint:var(--orange)"><.icon name="hero-clock" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Rest timer"
            )}</span></span><span class="lrow-v">{seconds_label(@state["restSec"], @locale)}</span><.icon
              name="hero-chevron-right"
              class="lrow-c"
            />
          </button>
          <button class="lrow tap" phx-click="setting:open" phx-value-key="restPauseSec">
            <span class="lrow-i" style="--tint:var(--acc)"><.icon name="hero-bolt" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Rest-pause rest"
            )}</span></span><span class="lrow-v">{seconds_label(@state["restPauseSec"], @locale)}</span><.icon
              name="hero-chevron-right"
              class="lrow-c"
            />
          </button>
        </div>
      </section>

      <section class="sect">
        <span class="sect-t">{t(@locale, "Appearance")}</span>
        <div class="sect-b">
          <div class="lrow">
            <span class="lrow-i" style="--tint:var(--indigo)"><.icon name="hero-moon" /></span><span class="lrow-m"><span class="lrow-t">{t(
              @locale,
              "Theme"
            )}</span></span>
            <div class="seg seg-inline settings-theme">
              <button
                :for={
                  {value, label} <- [
                    {"dark", t(@locale, "Dark")},
                    {"light", t(@locale, "Light")},
                    {"system", t(@locale, "System")}
                  ]
                }
                class={if @state["theme"] == value, do: "on"}
                phx-click="setting:set"
                phx-value-key="theme"
                phx-value-setting={value}
              >{label}</button>
            </div>
          </div>
          <div class="lrow accent-row">
            <span class="lrow-m"><span class="lrow-t">{t(@locale, "Accent color")}</span></span>
            <div class="swatches">
              <button
                :for={accent <- @accents}
                type="button"
                class={["swatch", @state["accent"] == accent.key && "on"]}
                style={"background:#{accent.color}"}
                phx-click="setting:set"
                phx-value-key="accent"
                phx-value-setting={accent.key}
                aria-label={accent.label}
                aria-pressed={to_string(@state["accent"] == accent.key)}
              ></button>
            </div>
          </div>
        </div>
        <div class="sect-f">
          {t(
            @locale,
            if(@local_only, do: "Saved only in this browser.", else: "Saved with your account.")
          )}
        </div>
      </section>

      <div class="dim small settings-footer">
        tamagym<br />Exercise catalogue: hasaneyldrm/exercises-dataset
      </div>
    </div>
    """
  end

  attr :modal, :any, required: true
  attr :state, :map, required: true
  attr :locale, :string, required: true
  attr :search, :string, required: true
  attr :results, :list, required: true
  attr :ai_models, :list, required: true
  attr :ai_draft, :map, default: nil
  attr :ai_day_draft, :map, default: nil
  attr :ai_muscle_groups, :list, required: true
  attr :ai_alternatives, :list, required: true
  attr :ai_loading, :any, default: nil
  attr :ai_error, :string, default: nil

  def modal(assigns) do
    {kind, modal_value} = modal_info(assigns.modal)
    exercise_id = if kind in [:exercise, :add_exercise], do: modal_value
    exercise = exercise_id && exercise(assigns.state, exercise_id)

    {routine_config, routine_config_exercise, routine_config_bodyweight} =
      case {kind, modal_value} do
        {:routine_exercise, {routine_id, index}} ->
          routine = Enum.find(assigns.state["routines"], &(&1["id"] == routine_id))
          config = routine && Enum.at(routine["ex"], index)
          item = config && exercise(assigns.state, config["id"])
          bodyweight = item && (config["bodyweight"] || item["eq"] == "body weight")
          {config, item, bodyweight}

        _other ->
          {nil, nil, false}
      end

    routine_techniques = if routine_config, do: routine_set_techniques(routine_config), else: []
    planned_drop? = Enum.any?(routine_techniques, &(&1 && &1["type"] == "dropset"))

    routine_config_show_weight =
      !routine_config_bodyweight ||
        (routine_config && State.number(routine_config["weight"]) > 0) || planned_drop?

    remove_entry =
      if kind == :remove_exercise, do: Enum.at(assigns.state["active"]["entries"], modal_value)

    alternative_entry =
      if kind in [:ai_alternative_reason, :ai_alternatives] && assigns.state["active"] do
        Enum.at(assigns.state["active"]["entries"], modal_value)
      end

    alternative_exercise =
      alternative_entry && exercise(assigns.state, alternative_entry["id"])

    workout =
      if kind == :workout, do: Enum.find(assigns.state["workouts"], &(&1["id"] == modal_value))

    activity_workouts =
      if kind == :activity,
        do: Enum.filter(assigns.state["workouts"], &(&1["d"] == modal_value)),
        else: []

    day_date = if kind == :day_override, do: parse_date(modal_value)
    weekly_routine = day_date && routine_for_weekly_date(assigns.state, day_date)
    effective_routine = day_date && State.effective_routine(assigns.state, day_date)

    has_day_override =
      kind == :day_override && Map.has_key?(assigns.state["dayPlan"], modal_value)

    setting_options =
      if kind == :setting, do: setting_options(modal_value, assigns.locale), else: []

    setting_title = if kind == :setting, do: setting_title(modal_value, assigns.locale)

    recent_weights =
      assigns.state["bodyweight"]
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.take(5)

    suggested_weight =
      case List.first(recent_weights) do
        {row, _index} -> row["w"]
        nil -> 70
      end

    assigns =
      assign(assigns,
        kind: kind,
        exercise: exercise,
        exercise_id: exercise_id,
        routine_config: routine_config,
        routine_config_exercise: routine_config_exercise,
        routine_config_bodyweight: routine_config_bodyweight,
        routine_config_show_weight: routine_config_show_weight,
        routine_techniques: routine_techniques,
        remove_entry: remove_entry,
        alternative_entry: alternative_entry,
        alternative_exercise: alternative_exercise,
        modal_value: modal_value,
        workout: workout,
        activity_workouts: activity_workouts,
        day_date: day_date,
        weekly_routine: weekly_routine,
        effective_routine: effective_routine,
        has_day_override: has_day_override,
        setting_options: setting_options,
        setting_title: setting_title,
        recent_weights: recent_weights,
        suggested_weight: suggested_weight
      )

    ~H"""
    <div id="modal-root" class="open">
      <button class="mback" phx-click="modal:close" aria-label="Close"></button>
      <section class="sheet" role="dialog" aria-modal="true">
        <div class="grab"></div>
        <button class="sheet-close iconbtn" phx-click="modal:close" aria-label="Close"><.icon name="hero-x-mark" /></button>

        <div :if={@kind == :ai_week}>
          <h3>{t(@locale, "Plan my next 7 days")}</h3>
          <div class="muted small" style="margin-bottom:14px">
            {t(
              @locale,
              "Generate a complete commercial-gym split from today, including recovery days."
            )}
          </div>
          <.form
            for={to_form(%{"goal" => "general_fitness"})}
            phx-submit="ai:week-generate"
            class="lv-form"
          >
            <.input
              type="select"
              name="goal"
              value="general_fitness"
              label={t(@locale, "Choose your goal")}
              options={ai_goal_options(@locale)}
              required
            />
            <div :if={@ai_error} class="ai-error">{@ai_error}</div>
            <button
              class="btn primary"
              type="submit"
              phx-disable-with={t(@locale, "Generating your plan…")}
            >
              <.icon name="hero-sparkles" />{t(@locale, "Generate plan")}
            </button>
          </.form>
          <div class="dim small ai-safety-note">
            {t(
              @locale,
              "AI-generated plans are suggestions. Review the exercises and loads before training."
            )}
          </div>
        </div>

        <div :if={@kind == :ai_week_loading} class="ai-loading">
          <.icon name="hero-sparkles" />
          <h3>{t(@locale, "Generating your plan…")}</h3>
          <div class="muted small">{selected_ai_model(@state, @ai_models)}</div>
        </div>

        <div :if={@kind == :ai_week_preview && @ai_draft}>
          <h3>{t(@locale, "Review your 7-day plan")}</h3>
          <div class="muted small" style="margin-bottom:14px">{@ai_draft["summary"]}</div>
          <div class="ai-week-preview">
            <article :for={day <- @ai_draft["days"]} class="card ai-day">
              <div class="row between">
                <div>
                  <div class="small dim">{day["date"]}</div>
                  <div class="tt">{day["name"]}</div>
                </div>
                <span class={if day["kind"] == "rest", do: "tag", else: "tag acc"}>
                  <.icon name={if day["kind"] == "rest", do: "hero-moon", else: "hero-dumbbell"} />
                  {t(@locale, if(day["kind"] == "rest", do: "Rest", else: "Workout"))}
                </span>
              </div>
              <div class="muted small ai-day-reason">{day["rationale"]}</div>
              <div :if={day["kind"] == "workout"} class="ai-day-exercises">
                <div :for={prescription <- day["exercises"]} class="row between small">
                  <span class="capitalize">
                    {exercise_name(@state, prescription["exercise_id"])}
                    <span
                      :if={label = ai_technique_label(prescription, @locale)}
                      class="ai-technique-label"
                    >{label}</span>
                  </span>
                  <span class="dim">
                    {prescription["sets"]} × {prescription["reps"]}
                    <span :if={State.number(prescription["weight"]) > 0}>
                      · {format_number(prescription["weight"])} {@state["unit"]}
                    </span>
                  </span>
                </div>
              </div>
            </article>
          </div>
          <div class="dim small ai-safety-note">
            {t(
              @locale,
              "AI-generated plans are suggestions. Review the exercises and loads before training."
            )}
          </div>
          <div class="dim small ai-safety-note">
            {t(@locale, "Applying also replaces your recurring weekly schedule.")}
          </div>
          <div class="confirm-actions">
            <button class="btn primary" phx-click="ai:week-apply">
              {t(@locale, "Apply plan")}
            </button>
            <button class="btn" phx-click="ai:week-open">
              {t(@locale, "Generate again")}
            </button>
          </div>
        </div>

        <div :if={@kind == :ai_model}>
          <h3>{t(@locale, "AI model")}</h3>
          <div class="list setting-options">
            <button
              :for={model <- @ai_models}
              class="item"
              phx-click="ai:model-select"
              phx-value-model={model}
            >
              <div class="grow" style="text-align:left">
                <div class="tt">{model}</div>
              </div>
              <.icon
                :if={selected_ai_model(@state, @ai_models) == model}
                name="hero-check"
                class="accent"
              />
            </button>
          </div>
        </div>

        <div :if={@kind == :ai_alternative_reason && @alternative_exercise}>
          <h3>{t(@locale, "Why can't you do this exercise?")}</h3>
          <div class="item ai-original-exercise">
            <img class="thumb" src={exercise_thumbnail(@state, @alternative_exercise["id"])} alt="" />
            <div class="grow">
              <div class="tt capitalize">{@alternative_exercise["n"]}</div>
            </div>
          </div>
          <div class="list ai-reasons">
            <button
              :for={reason <- ai_alternative_reason_options(@locale)}
              class="item"
              phx-click="ai:alternatives-generate"
              phx-value-index={@modal_value}
              phx-value-reason={reason.value}
            >
              <div class="grow">
                <div class="tt">{reason.label}</div>
              </div>
              <.icon name="hero-chevron-right" class="chev" />
            </button>
          </div>
        </div>

        <div :if={@kind == :ai_alternatives && @ai_loading == :alternatives} class="ai-loading">
          <.icon name="hero-sparkles" />
          <h3>{t(@locale, "Finding alternatives…")}</h3>
        </div>

        <div :if={@kind == :ai_alternatives && @ai_loading != :alternatives}>
          <h3>{t(@locale, "Choose an alternative")}</h3>
          <div :if={@ai_error} class="ai-error">{@ai_error}</div>
          <div class="list ai-alternatives">
            <button
              :for={alternative <- @ai_alternatives}
              class="item"
              phx-click="ai:alternative-select"
              phx-value-index={@modal_value}
              phx-value-id={alternative["exercise_id"]}
            >
              <img
                class="thumb"
                src={exercise_thumbnail(@state, alternative["exercise_id"])}
                alt=""
              />
              <div class="grow" style="text-align:left">
                <div class="tt capitalize">
                  {exercise_name(@state, alternative["exercise_id"])}
                </div>
                <div class="ss">{alternative["reason"]}</div>
              </div>
              <.icon name="hero-check" class="accent" />
            </button>
          </div>
          <button
            :if={@ai_error}
            class="btn"
            phx-click="ai:alternatives-open"
            phx-value-index={@modal_value}
          >{t(@locale, "Generate again")}</button>
        </div>

        <div :if={@kind in [:workout_exercise, :swap_exercise, :routine_exercise_picker]}>
          <h3>
            {t(@locale, if(@kind == :swap_exercise, do: "Swap exercise", else: "Add exercise"))}
          </h3>
          <.search_box locale={@locale} search={@search} />
          <div class="list workout-exercise-picker">
            <button
              :for={exercise <- Enum.take(@results, 40)}
              class="item"
              phx-click={
                case @kind do
                  :swap_exercise -> "workout:swap-exercise"
                  :routine_exercise_picker -> "routine:add-exercise"
                  _kind -> "workout:add-exercise"
                end
              }
              phx-value-index={if @kind == :swap_exercise, do: @modal_value}
              phx-value-id={exercise["id"]}
            >
              <img class="thumb" src={~p"/img/#{exercise["img"]}"} loading="lazy" alt="" /><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt capitalize">{exercise["n"]}</div><div class="ss capitalize">
                  {exercise["tg"] || exercise["bp"]} · {exercise["eq"]}
                </div>
              </div><.icon name={if @kind == :swap_exercise, do: "hero-arrow-path", else: "hero-plus"} />
            </button>
          </div>
          <div :if={@results == []} class="empty">{t(@locale, "No match")}</div>
        </div>

        <div :if={@kind == :routine_exercise && @routine_config && @routine_config_exercise}>
          <h3 class="capitalize">{@routine_config_exercise["n"]}</h3>
          <div class="routine-config-media">
            <.exercise_media
              :if={@routine_config_exercise["gif"]}
              exercise={@routine_config_exercise}
              locale={@locale}
              context="routine-config"
            />
            <img
              :if={is_nil(@routine_config_exercise["gif"])}
              class="routine-config-static"
              src={exercise_thumbnail(@state, @routine_config["id"])}
              alt={@routine_config_exercise["n"]}
            />
          </div>
          <div class="routine-config-meta">
            <div class="muted small capitalize">
              {@routine_config_exercise["tg"] || @routine_config_exercise["bp"]} · {@routine_config_exercise[
                "eq"
              ]}
            </div>
            <div class="small dim">{t(@locale, "Changes save automatically")}</div>
          </div>
          <.form
            for={to_form(%{})}
            id="routine-config-form"
            phx-change="routine:configure-exercise"
            class="routine-config-form"
          >
            <input type="hidden" name="index" value={elem(@modal_value, 1)} />
            <div class="config-step">
              <span class="config-label">{t(@locale, "sets")}</span><div class="stp">
                <button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="sets"
                  phx-value-direction="down"
                ><.icon name="hero-minus" /></button><span class="val"><.input
                  class="num"
                  name="sets"
                  type="number"
                  value={@routine_config["sets"] || 3}
                  min="1"
                  max="20"
                /></span><button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="sets"
                  phx-value-direction="up"
                ><.icon name="hero-plus" /></button>
              </div>
            </div>
            <div class="config-step">
              <span class="config-label">{t(@locale, "reps")}</span><div class="stp">
                <button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="reps"
                  phx-value-direction="down"
                ><.icon name="hero-minus" /></button><span class="val"><.input
                  class="num"
                  name="reps"
                  type="number"
                  value={@routine_config["reps"] || 10}
                  min="0"
                /></span><button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="reps"
                  phx-value-direction="up"
                ><.icon name="hero-plus" /></button>
              </div>
            </div>
            <div :if={@routine_config_show_weight} class="config-step">
              <span class="config-label">{t(
                @locale,
                if(@routine_config_bodyweight, do: "added", else: "weight")
              )} ({@state["unit"]})</span><div class="stp">
                <button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="weight"
                  phx-value-direction="down"
                ><.icon name="hero-minus" /></button><span class="val"><.input
                  class="num"
                  name="weight"
                  type="number"
                  value={@routine_config["weight"] || 0}
                  min="0"
                  step="0.5"
                /></span><button
                  type="button"
                  phx-click="routine:step-exercise"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-field="weight"
                  phx-value-direction="up"
                ><.icon name="hero-plus" /></button>
              </div>
            </div>
            <input :if={!@routine_config_show_weight} type="hidden" name="weight" value="0" />
          </.form>

          <h4 class="sec routine-intensifier-title">{t(@locale, "Set techniques")}</h4>
          <div class="routine-set-techniques">
            <article
              :for={{technique, set_index} <- Enum.with_index(@routine_techniques)}
              class="routine-set-technique"
            >
              <div class="row between technique-heading">
                <b>{t(@locale, "Set")} {set_index + 1}</b><span :if={technique} class="tag acc">{t(
                  @locale,
                  if(technique["type"] == "dropset", do: "Drop-set", else: "Rest-pause")
                )}</span>
              </div>
              <div class="seg intensifier-seg">
                <button
                  :for={
                    {type, label} <- [
                      {"none", t(@locale, "None")},
                      {"dropset", t(@locale, "Drop-set")},
                      {"restpause", t(@locale, "Rest-pause")}
                    ]
                  }
                  type="button"
                  class={if ((technique && technique["type"]) || "none") == type, do: "on"}
                  phx-click="routine:set-technique"
                  phx-value-index={elem(@modal_value, 1)}
                  phx-value-set={set_index}
                  phx-value-type={type}
                >{label}</button>
              </div>

              <div
                :if={technique && technique["type"] == "dropset"}
                class="routine-intensifier-controls"
              >
                <div class="config-step">
                  <span class="config-label">{t(@locale, "Drops")}</span><div class="stp">
                    <button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="count"
                      phx-value-direction="down"
                    ><.icon name="hero-minus" /></button><span class="val intensity-value">{technique[
                      "count"
                    ]}</span><button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="count"
                      phx-value-direction="up"
                    ><.icon name="hero-plus" /></button>
                  </div>
                </div>
                <div class="config-step">
                  <span class="config-label">{t(@locale, "Weight drop (%)")}</span><div class="stp">
                    <button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="pct"
                      phx-value-direction="down"
                    ><.icon name="hero-minus" /></button><span class="val intensity-value">{technique[
                      "pct"
                    ]}%</span><button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="pct"
                      phx-value-direction="up"
                    ><.icon name="hero-plus" /></button>
                  </div>
                </div>
              </div>

              <div
                :if={technique && technique["type"] == "restpause"}
                class="routine-intensifier-controls"
              >
                <div class="config-step">
                  <span class="config-label">{t(@locale, "Extra reps")}</span><div class="stp">
                    <button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="totalReps"
                      phx-value-direction="down"
                    ><.icon name="hero-minus" /></button><span class="val intensity-value">{technique[
                      "totalReps"
                    ]}</span><button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="totalReps"
                      phx-value-direction="up"
                    ><.icon name="hero-plus" /></button>
                  </div>
                </div>
                <div class="config-step">
                  <span class="config-label">{t(@locale, "Rest (s)")}</span><div class="stp">
                    <button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="restSec"
                      phx-value-direction="down"
                    ><.icon name="hero-minus" /></button><span class="val intensity-value">{technique[
                      "restSec"
                    ]}s</span><button
                      type="button"
                      phx-click="routine:set-technique-step"
                      phx-value-index={elem(@modal_value, 1)}
                      phx-value-set={set_index}
                      phx-value-field="restSec"
                      phx-value-direction="up"
                    ><.icon name="hero-plus" /></button>
                  </div>
                </div>
              </div>
            </article>
          </div>
          <div class="small dim intensifier-help">
            {t(
              @locale,
              "Choose a technique only for the sets that should use it — for example, make just the last set a drop set."
            )}
          </div>

          <button
            class="btn danger routine-config-remove"
            phx-click="routine:remove-exercise"
            phx-value-index={elem(@modal_value, 1)}
          ><.icon name="hero-trash" />{t(@locale, "Remove exercise")}</button>
        </div>

        <div :if={@kind == :remove_exercise && @remove_entry}>
          <h3>{t(@locale, "Remove exercise")}?</h3>
          <div class="muted small" style="margin-bottom:16px">
            {if Enum.any?(@remove_entry["sets"], & &1["done"]),
              do: t(@locale, "The sets you logged for this exercise in this session will be lost."),
              else: t(@locale, "This removes the exercise from your current session.")}
          </div>
          <div class="confirm-actions">
            <button
              class="btn danger"
              phx-click="workout:remove-exercise"
              phx-value-index={@modal_value}
            >{t(@locale, "Remove")}</button><button class="btn" phx-click="modal:close">{t(
              @locale,
              "Cancel"
            )}</button>
          </div>
        </div>

        <div :if={@kind == :finish_workout}>
          <h3>{t(@locale, "Finish workout?")}</h3>
          <div :if={unfinished_sets(@state) > 0} class="muted small" style="margin-bottom:16px">
            {unfinished_sets(@state)} {t(@locale, "unfinished sets will remain uncompleted.")}
          </div>
          <div :if={unfinished_sets(@state) == 0} class="muted small" style="margin-bottom:16px">
            {t(@locale, "All sets are complete. Great work.")}
          </div>
          <div class="confirm-actions">
            <button class="btn primary" phx-click="workout:finish">{t(@locale, "Finish workout")}</button><button
              class="btn"
              phx-click="modal:close"
            >{t(@locale, "Continue workout")}</button>
          </div>
        </div>

        <div :if={@kind == :discard_workout}>
          <h3>{t(@locale, "Discard workout?")}</h3>
          <div class="muted small" style="margin-bottom:16px">
            {t(@locale, "The sets you logged in this session will be lost.")}
          </div>
          <div class="confirm-actions">
            <button class="btn danger" phx-click="workout:cancel">{t(@locale, "Discard")}</button><button
              class="btn"
              phx-click="modal:close"
            >{t(@locale, "Continue workout")}</button>
          </div>
        </div>

        <div :if={@kind == :setting}>
          <h3>{@setting_title}</h3>
          <div class="list setting-options">
            <button
              :for={option <- @setting_options}
              class="item"
              phx-click="setting:set"
              phx-value-key={@modal_value}
              phx-value-setting={option.value}
            >
              <div class="grow" style="text-align:left">
                <div class="tt">{option.label}</div><div :if={option[:subtitle]} class="ss">
                  {option.subtitle}
                </div>
              </div><.icon
                :if={to_string(@state[@modal_value]) == to_string(option.value)}
                name="hero-check"
                class="accent"
              />
            </button>
          </div>
        </div>

        <div :if={@kind == :sign_out}>
          <h3>{t(@locale, "Sign out?")}</h3>
          <div class="muted small" style="margin-bottom:16px">
            {t(
              @locale,
              "Your latest changes are saved to your account before this browser signs out."
            )}
          </div>
          <.form for={to_form(%{})} action={~p"/session"} method="delete" class="confirm-actions">
            <button class="btn danger" type="submit">{t(@locale, "Sign out")}</button>
            <button class="btn" type="button" phx-click="modal:close">{t(@locale, "Cancel")}</button>
          </.form>
        </div>

        <div :if={@kind in [:bodyweight, :bodyweight_start]}>
          <h3>{t(@locale, "Log body weight")}</h3>
          <div class="muted small">
            {t(@locale, "Today")} · {date_label(@locale, Date.utc_today())}
          </div>
          <.form for={to_form(%{})} phx-submit="bodyweight:save" class="weight-form">
            <div class="weight-entry">
              <.input
                name="weight"
                type="number"
                value={@suggested_weight}
                min="1"
                step="0.1"
                inputmode="decimal"
                autofocus
                required
              /><span>{@state["unit"]}</span>
            </div>
            <button class="btn primary" type="submit">{t(
              @locale,
              if(@kind == :bodyweight_start, do: "Save & start workout", else: "Save")
            )}</button>
          </.form>
          <button
            :if={@kind == :bodyweight_start}
            class="btn ghost dim"
            phx-click="workout:start-without-weight"
          >{t(@locale, "Start without weighing in")}</button>
          <div :if={@recent_weights != []}>
            <h4 class="sec">{t(@locale, "Recent weigh-ins")}</h4>
            <div class="list recent-weights">
              <div :for={{row, index} <- @recent_weights} class="row between">
                <span class="small muted">{row["d"]}</span><span class="row" style="gap:10px"><b>{format_number(
                  row["w"]
                )} {@state["unit"]}</b><button
                  class="iconbtn weight-delete"
                  phx-click="bodyweight:delete"
                  phx-value-index={index}
                  aria-label={t(@locale, "Delete")}
                ><.icon name="hero-trash" /></button></span>
              </div>
            </div>
          </div>
        </div>

        <div :if={@kind == :goal}>
          <h3>{t(@locale, "Goal")}</h3>
          <.form for={to_form(%{})} phx-submit="goal:save" class="weight-form">
            <div class="weight-entry">
              <.input
                name="weight"
                type="number"
                value={@state["targetW"] || @suggested_weight}
                min="1"
                step="0.1"
                inputmode="decimal"
                required
              /><span>{@state["unit"]}</span>
            </div>
            <button class="btn primary" type="submit">{t(@locale, "Save")}</button>
          </.form>
          <button :if={@state["targetW"]} class="btn danger" phx-click="goal:remove">{t(
            @locale,
            "Remove"
          )}</button>
        </div>

        <div :if={@kind == :exercise && @exercise}>
          <h3 class="capitalize exercise-detail-title">{@exercise["n"]}</h3>
          <.exercise_media exercise={@exercise} locale={@locale} context="detail" />
          <div class="row detail-tags">
            <span class="tag acc">{@exercise["bp"]}</span><span :if={@exercise["tg"]} class="tag"><.icon name="hero-target" />{@exercise[
              "tg"
            ]}</span><span class="tag"><.icon name="hero-dumbbell" />{@exercise["eq"]}</span><span
              :for={muscle <- Enum.take(List.wrap(@exercise["sm"]), 3)}
              class="tag"
            >{muscle}</span>
          </div>
          <div :if={best_weight(@state, @exercise["id"]) > 0} class="small row best-line">
            <.icon name="hero-trophy" />{t(@locale, "Best")}:
            <b class="accent">{format_number(best_weight(@state, @exercise["id"]))} {@state["unit"]}</b>
          </div>
          <button
            class="btn primary detail-add"
            phx-click="exercise:add-plan"
            phx-value-id={@exercise["id"]}
          ><.icon name="hero-plus" />{t(@locale, "Add to my plan")}</button>
          <div :if={List.wrap(@exercise["st"]) != []}>
            <h4 class="sec">
              {t(@locale, "How to")}
              <span class="dim">· {t(@locale, "instructions in English")}</span>
            </h4><ol class="steps-list">
              <li :for={step <- List.wrap(@exercise["st"])}>{step}</li>
            </ol>
          </div>
        </div>

        <div :if={@kind == :add_exercise && @exercise}>
          <h3 class="capitalize">{t(@locale, "Add to my plan")} · {@exercise["n"]}</h3>
          <div class="list">
            <button
              :for={routine <- @state["routines"]}
              class="item"
              phx-click="exercise:add-to-routine"
              phx-value-exercise={@exercise["id"]}
              phx-value-routine={routine["id"]}
            ><span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
              class="grow"
              style="text-align:left"
            >
              <div class="tt">{routine["name"]}</div><div class="ss">
                {length(routine["ex"])} {t(@locale, "Exercises")}
              </div>
            </div><.icon name="hero-plus" /></button>
            <button
              class="item"
              phx-click="exercise:add-to-new-routine"
              phx-value-exercise={@exercise["id"]}
            ><span class="lrow-i"><.icon name="hero-sparkles" /></span><div
              class="grow"
              style="text-align:left"
            >
              <div class="tt">{t(@locale, "New routine")}</div>
            </div><.icon name="hero-plus" /></button>
          </div>
        </div>

        <div :if={@kind == :custom_exercise}>
          <h3>{t(@locale, "Create your own exercise")}</h3>
          <.form for={to_form(%{})} phx-submit="custom:add" class="lv-form">
            <.input name="name" value="" label={t(@locale, "Name")} required />
            <.input name="body_part" value="" label={t(@locale, "Body part")} required />
            <.input name="equipment" value="" label={t(@locale, "Equipment")} required />
            <button type="submit" class="btn primary"><.icon name="hero-plus" />{t(@locale, "Add")}</button>
          </.form>
        </div>

        <div :if={@kind == :day_schedule}>
          <h3>{day_name(@locale, @modal_value)}</h3>
          <button
            :if={@ai_models != []}
            class="item ai-day-entry"
            phx-click="ai:day-open"
            phx-value-day={@modal_value}
          >
            <span class="lrow-i" style="--tint:var(--purple)"><.icon name="hero-sparkles" /></span>
            <div class="grow">
              <div class="tt">{t(@locale, "Generate routine with AI")}</div>
              <div class="ss">
                {t(@locale, "Build a new commercial-gym routine for this weekday.")}
              </div>
            </div>
            <.icon name="hero-chevron-right" class="chev" />
          </button>
          <h4 class="sec">{t(@locale, "Routines")}</h4>
          <div class="list">
            <button
              class="item"
              phx-click="schedule:assign"
              phx-value-day={@modal_value}
              phx-value-routine=""
            >
              <span class="lrow-i" style="background:var(--surface-3)"><.icon name="hero-moon" /></span><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt">{t(@locale, "Rest day")}</div>
              </div><.icon
                :if={is_nil(routine_for_day(@state, @modal_value))}
                name="hero-check"
                class="accent"
              />
            </button>
            <button
              :for={routine <- @state["routines"]}
              class="item"
              phx-click="schedule:assign"
              phx-value-day={@modal_value}
              phx-value-routine={routine["id"]}
            >
              <span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt">{routine["name"]}</div><div class="ss">
                  {length(routine["ex"])} {t(@locale, "Exercises")}
                </div>
              </div><.icon
                :if={@state["week"][@modal_value] == routine["id"]}
                name="hero-check"
                class="accent"
              />
            </button>
          </div>
          <div :if={@state["routines"] == []} class="muted small" style="margin-top:12px">
            {t(@locale, "Create a routine first, then assign it here.")}
          </div>
        </div>

        <div :if={@kind == :ai_day}>
          <div class="dim small">{day_name(@locale, @modal_value)}</div>
          <h3>{t(@locale, "Generate routine with AI")}</h3>
          <div class="muted small ai-day-intro">
            {t(@locale, "Choose muscle groups")}. {t(
              @locale,
              "Select between 1 and 3 muscle groups."
            )}
          </div>
          <div class="ai-muscle-grid">
            <button
              :for={option <- ai_muscle_group_options(@locale)}
              type="button"
              class={["ai-muscle-option", option.value in @ai_muscle_groups && "on"]}
              phx-click="ai:day-muscle-toggle"
              phx-value-group={option.value}
              aria-pressed={to_string(option.value in @ai_muscle_groups)}
              disabled={length(@ai_muscle_groups) >= 3 && option.value not in @ai_muscle_groups}
            >
              <span>{option.label}</span>
              <.icon :if={option.value in @ai_muscle_groups} name="hero-check" />
            </button>
          </div>
          <div :if={@ai_error} class="ai-error">{@ai_error}</div>
          <button
            class="btn primary ai-day-submit"
            phx-click="ai:day-generate"
            phx-value-day={@modal_value}
            disabled={@ai_muscle_groups == []}
            phx-disable-with={t(@locale, "Generating routine…")}
          >
            <.icon name="hero-sparkles" />{t(@locale, "Generate routine")}
          </button>
        </div>

        <div :if={@kind == :ai_day_loading} class="ai-loading">
          <.icon name="hero-sparkles" />
          <h3>{t(@locale, "Generating routine…")}</h3>
          <div class="muted small">{day_name(@locale, @modal_value)}</div>
          <div class="muted small">{selected_ai_model(@state, @ai_models)}</div>
        </div>

        <div :if={@kind == :ai_day_preview && @ai_day_draft}>
          <div class="dim small">{day_name(@locale, @modal_value)}</div>
          <h3>{t(@locale, "Review AI routine")}</h3>
          <div class="card ai-day-routine-summary">
            <div class="tt">{@ai_day_draft["name"]}</div>
            <div class="muted small">{@ai_day_draft["rationale"]}</div>
          </div>
          <div class="list ai-day-routine-exercises">
            <div :for={prescription <- @ai_day_draft["exercises"]} class="item">
              <span class="lrow-i"><.icon name="hero-dumbbell" /></span>
              <div class="grow">
                <div class="tt capitalize">
                  {exercise_name(@state, prescription["exercise_id"])}
                </div>
                <div class="ss">
                  {prescription["sets"]} × {prescription["reps"]}
                  <span :if={State.number(prescription["weight"]) > 0}>
                    · {format_number(prescription["weight"])} {@state["unit"]}
                  </span>
                </div>
                <div
                  :if={label = ai_technique_label(prescription, @locale)}
                  class="ai-technique-label"
                >
                  {label}
                </div>
              </div>
            </div>
          </div>
          <div class="dim small ai-safety-note">
            {t(
              @locale,
              "A new routine will be created and assigned to this weekday. Existing routines are kept."
            )}
          </div>
          <div class="confirm-actions">
            <button
              class="btn primary"
              phx-click="ai:day-apply"
              phx-value-day={@modal_value}
            >
              {t(@locale, "Create and assign")}
            </button>
            <button
              class="btn"
              phx-click="ai:day-open"
              phx-value-day={@modal_value}
            >
              {t(@locale, "Generate again")}
            </button>
          </div>
        </div>

        <div :if={@kind == :day_override && @day_date}>
          <h3>{date_label(@locale, @day_date)}</h3>
          <div class="muted small" style="margin-bottom:12px">
            {t(@locale, "Weekly plan:")} {if @weekly_routine,
              do: @weekly_routine["name"],
              else: t(@locale, "Rest")}
            <span :if={@has_day_override} style="color:var(--orange)"> · {t(
              @locale,
              "changed for this day"
            )}</span><br />
            {t(@locale, "Pick what to train today.")}
          </div>
          <div class="list">
            <button
              :for={routine <- @state["routines"]}
              class="item"
              phx-click="day:assign"
              phx-value-date={@modal_value}
              phx-value-routine={routine["id"]}
            >
              <span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt">{routine["name"]}</div><div class="ss">
                  {length(routine["ex"])} {t(@locale, "Exercises")}
                </div>
              </div><.icon
                :if={@effective_routine && @effective_routine["id"] == routine["id"]}
                name="hero-check"
                class="accent"
              />
            </button>
            <button
              class="item"
              phx-click="day:assign"
              phx-value-date={@modal_value}
              phx-value-routine="rest"
            >
              <span class="lrow-i" style="background:var(--surface-3)"><.icon name="hero-moon" /></span><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt">{t(@locale, "Rest / skip this day")}</div>
              </div><.icon :if={is_nil(@effective_routine)} name="hero-check" class="accent" />
            </button>
            <button
              :if={@has_day_override}
              class="item"
              phx-click="day:assign"
              phx-value-date={@modal_value}
              phx-value-routine=""
            >
              <span class="lrow-i" style="background:var(--surface-3)"><.icon name="hero-arrow-path" /></span><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt">{t(@locale, "Back to weekly plan")}</div>
              </div>
            </button>
          </div>
        </div>

        <div :if={@kind == :stats_exercise}>
          <h3>{t(@locale, "Exercise progress")}</h3>
          <div class="list stats-exercise-picker">
            <button
              :for={id <- stats_exercise_ids(@state)}
              class="item"
              phx-click="stats:exercise-select"
              phx-value-id={id}
            >
              <img class="thumb" src={exercise_thumbnail(@state, id)} alt="" /><div
                class="grow"
                style="text-align:left"
              >
                <div class="tt capitalize">{exercise_name(@state, id)}</div><div class="ss">
                  {format_number(best_weight(@state, id))} {@state["unit"]}
                </div>
              </div><.icon name="hero-chevron-right" />
            </button>
          </div>
        </div>

        <div :if={@kind == :activity}>
          <h3>{@modal_value}</h3>
          <div class="list">
            <button
              :for={workout <- @activity_workouts}
              class="item"
              phx-click="workout:open"
              phx-value-id={workout["id"]}
            ><span class="lrow-i"><.icon name="hero-dumbbell" /></span><div
              class="grow"
              style="text-align:left"
            >
              <div class="tt">{workout["name"] || t(@locale, "Workout")}</div><div class="ss">
                {length(workout["entries"])} {t(@locale, "Exercises")} · {format_number(
                  workout["vol"] || State.workout_volume(workout)
                )} {@state["unit"]}
              </div>
            </div><.icon name="hero-chevron-right" /></button>
          </div>
        </div>

        <div :if={@kind == :workout && @workout}>
          <h3>{@workout["name"] || t(@locale, "Workout")}</h3>
          <div class="muted small" style="margin-bottom:12px">
            {@workout["d"]} · {format_number(@workout["vol"] || State.workout_volume(@workout))} {@state[
              "unit"
            ]}
          </div>
          <div class="list workout-detail-list">
            <div :for={entry <- @workout["entries"]} class="item">
              <span class="lrow-i"><.icon name="hero-dumbbell" /></span><div class="grow">
                <div class="tt capitalize">{exercise_name(@state, entry["id"])}</div><div class="ss">
                  {entry["sets"]
                  |> Enum.filter(& &1["done"])
                  |> Enum.map_join(" · ", fn set ->
                    "#{format_number(set["w"])} #{@state["unit"]} × #{set["r"]}"
                  end)}
                </div>
              </div>
            </div>
          </div>
          <button class="btn ghost" phx-click="modal:close">{t(@locale, "Done")}</button>
        </div>
      </section>
    </div>
    """
  end

  attr :load, :map, required: true
  attr :body, :string, default: "male"
  attr :locale, :string, required: true

  def muscle_map(assigns) do
    assigns =
      assign(assigns,
        views: BodyMap.views(assigns.body, assigns.load),
        muscles: BodyMap.ranked(assigns.load) |> Enum.take(6)
      )

    ~H"""
    <div class="bodymap routine-bodymap" role="img" aria-label={t(@locale, "What this session hits")}>
      <svg :for={view <- @views} class="bm-v" viewBox={view.view_box}>
        <path :for={path <- view.paths} class={path.class} d={path.d}>
          <title :if={path.title}>{t(@locale, path.title)}</title>
        </path>
      </svg>
    </div>
    <div class="hm-legend" aria-label={"#{t(@locale, "Less")} #{t(@locale, "More")}"}>
      {t(@locale, "Less")}<i class="hm-c l0"></i><i class="hm-c l1"></i><i class="hm-c l2"></i><i class="hm-c l3"></i><i class="hm-c l4"></i>{t(
        @locale,
        "More"
      )}
    </div>
    <div class="mchips">
      <span :for={muscle <- @muscles} class="mchip">{t(@locale, BodyMap.muscle_name(muscle))}</span>
    </div>
    """
  end

  attr :exercise, :map, required: true
  attr :locale, :string, required: true
  attr :compact, :boolean, default: false
  attr :context, :string, default: "workout"

  def exercise_media(assigns) do
    ~H"""
    <div
      :if={@exercise["gif"]}
      id={"exercise-media-#{@context}-#{@exercise["id"]}"}
      class={["exmedia", @compact && "compact"]}
      phx-hook="ExerciseMedia"
      phx-update="ignore"
      data-gif={~p"/gif/#{@exercise["gif"]}"}
      data-still={~p"/img/#{@exercise["img"]}"}
      data-play-label={t(@locale, "tap to play")}
      data-pause-label={t(@locale, "tap to pause")}
      data-collapse-label={t(@locale, "Minimize animation")}
      data-expand-label={t(@locale, "Expand animation")}
    >
      <img decoding="async" draggable="false" src={~p"/gif/#{@exercise["gif"]}"} alt={@exercise["n"]} />
      <button
        :if={@context == "workout"}
        type="button"
        class="giftoggle"
        aria-label={t(@locale, "Minimize animation")}
      ><.icon name="hero-arrows-pointing-in" class="media-collapse" /><.icon
        name="hero-arrows-pointing-out"
        class="media-expand"
      /><span>{t(@locale, "Minimize")}</span></button>
      <span class="gifhint"><.icon name="hero-pause" /><span>{t(@locale, "tap to pause")}</span></span>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :goal, :any, default: nil
  attr :unit, :string, default: ""
  attr :locale, :string, required: true

  def weight_chart(assigns) do
    dots = chart_points(assigns.rows, assigns.goal)
    points = Enum.map_join(dots, " ", &"#{&1.x},#{&1.y}")

    assigns =
      assign(assigns,
        dots: dots,
        last: List.last(dots),
        points: points,
        area_points:
          if(length(dots) > 1, do: "34,108 #{points} #{List.last(dots).x},108", else: nil),
        goal_y: chart_goal(assigns.rows, assigns.goal),
        y_ticks: chart_y_ticks(assigns.rows, assigns.goal),
        x_ticks: chart_x_ticks(dots, assigns.locale),
        gradient_id: "#{assigns.id}-fill"
      )

    ~H"""
    <div
      :if={length(@rows) > 0}
      id={@id}
      class="chart chart-i home-weight-chart"
      phx-hook="PointChart"
      data-unit={@unit}
    >
      <svg viewBox="0 0 340 130" preserveAspectRatio="none" aria-label="Body weight chart">
        <defs>
          <linearGradient id={@gradient_id} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="var(--acc)" stop-opacity=".28" /><stop
              offset="1"
              stop-color="var(--acc)"
              stop-opacity="0"
            />
          </linearGradient>
        </defs>
        <g :for={tick <- @y_ticks}>
          <line
            x1="34"
            x2="328"
            y1={tick.y}
            y2={tick.y}
            stroke="var(--sep-op)"
            stroke-width="1"
            stroke-dasharray="2 4"
          />
          <text x="29" y={tick.y + 3.5} text-anchor="end" font-size="9.5" fill="var(--label-2)">
            {tick.label}
          </text>
        </g>
        <g :for={tick <- @x_ticks}>
          <line
            x1={tick.x}
            x2={tick.x}
            y1="10"
            y2="108"
            stroke="var(--sep-op)"
            stroke-width="1"
            stroke-dasharray="2 4"
          />
          <text x={tick.x} y="123" text-anchor={tick.anchor} font-size="9.5" fill="var(--label-2)">
            {tick.label}
          </text>
        </g>
        <line
          :if={@goal_y}
          x1="34"
          x2="328"
          y1={@goal_y}
          y2={@goal_y}
          stroke="var(--yellow)"
          stroke-width="1.6"
          stroke-dasharray="7 4"
        />
        <text
          :if={@goal_y}
          x="326"
          y={@goal_y - 5}
          text-anchor="end"
          font-size="9.5"
          font-weight="700"
          fill="var(--yellow)"
        >
          {format_number(@goal)}
        </text>
        <polygon :if={@area_points} points={@area_points} fill={"url(##{@gradient_id})"} />
        <polyline
          :if={length(@dots) > 1}
          points={@points}
          fill="none"
          stroke="var(--acc)"
          stroke-width="2.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <circle cx={@last.x} cy={@last.y} r="4" fill="var(--acc)" />
        <circle
          :for={point <- @dots}
          class="chart-hit-point"
          cx={point.x}
          cy={point.y}
          r="10"
          fill="transparent"
          tabindex="0"
          role="button"
          aria-label={"#{point.date}: #{format_number(point.value)} #{@unit}"}
          data-chart-point
          data-date={point.date}
          data-value={format_number(point.value)}
        />
        <g class="chart-selection" hidden>
          <line
            class="chart-select-v"
            y1="10"
            y2="108"
            stroke="var(--label-3)"
            stroke-width="1"
            stroke-dasharray="3 3"
            vector-effect="non-scaling-stroke"
          />
          <line
            class="chart-select-h"
            x1="34"
            x2="328"
            stroke="var(--label-3)"
            stroke-width="1"
            stroke-dasharray="3 3"
            vector-effect="non-scaling-stroke"
          />
          <circle
            class="chart-select-dot"
            r="6"
            fill="var(--acc)"
            stroke="var(--surface)"
            stroke-width="2"
            vector-effect="non-scaling-stroke"
          />
        </g>
      </svg>
      <div class="ctip" hidden></div>
    </div>
    """
  end

  attr :locale, :string, required: true
  attr :search, :string, required: true

  def search_box(assigns) do
    ~H"""
    <.form
      for={to_form(%{"query" => @search})}
      id="exercise-search"
      phx-change="search"
      class="search"
      style="margin-bottom:10px"
    >
      <.icon name="hero-magnifying-glass" />
      <.input name="query" value={@search} placeholder={t(@locale, "Search…")} phx-debounce="250" />
    </.form>
    """
  end

  attr :action, :atom, required: true
  attr :locale, :string, required: true
  attr :state, :map, required: true

  def navigation(assigns) do
    routine = State.effective_routine(assigns.state)
    start_id = (routine && routine["ex"] != [] && routine["id"]) || ""
    assigns = assign(assigns, :start_id, start_id)

    ~H"""
    <nav id="tabbar">
      <button class={if @action == :home, do: "on"} phx-click="nav" phx-value-to="/home">
        <.icon name="hero-home" /><span>{t(@locale, "Home")}</span>
      </button>
      <button class={if @action in [:plan, :routine], do: "on"} phx-click="nav" phx-value-to="/plan">
        <.icon name="hero-calendar-days" /><span>{t(@locale, "Plan")}</span>
      </button>
      <button
        class={["start", @state["active"] && "rec"]}
        phx-click="workout:prepare"
        phx-value-id={@start_id}
      >
        <span class="cir"><.icon name={if @state["active"], do: "hero-play", else: "hero-dumbbell"} /></span>
        <span>{t(@locale, if(@state["active"], do: "Resume", else: "Start"))}</span>
      </button>
      <button class={if @action in [:stats, :history], do: "on"} phx-click="nav" phx-value-to="/stats">
        <.icon name="hero-chart-bar" /><span>{t(@locale, "Stats")}</span>
      </button>
      <button class={if @action == :library, do: "on"} phx-click="nav" phx-value-to="/library">
        <.icon name="hero-list-bullet" /><span>{t(@locale, "Exercises")}</span>
      </button>
    </nav>
    """
  end

  def t("es", text), do: Map.get(@es, text, text)
  def t(_locale, text), do: text

  defp routine_config(state, routine_id, index) do
    routine = Enum.find(state["routines"], &(&1["id"] == routine_id))
    routine && Enum.at(routine["ex"], index)
  end

  defp routine_set_techniques(config) do
    routine_set_techniques(config, max(1, State.integer(config["sets"], 3)))
  end

  defp routine_set_techniques(config, count) do
    count = max(1, State.integer(count, 3))
    saved = List.wrap(config["setTechniques"])
    legacy = config["intensifier"]

    Enum.map(0..(count - 1), fn index ->
      if index < length(saved), do: Enum.at(saved, index), else: legacy
    end)
  end

  defp routine_config_label(state, config, locale) do
    item = exercise(state, config["id"])
    bodyweight? = item && (config["bodyweight"] || item["eq"] == "body weight")

    base =
      "#{State.integer(config["sets"], 3)} #{t(locale, "sets")} × #{State.integer(config["reps"], 10)} #{t(locale, "reps")}"

    base =
      cond do
        bodyweight? && State.number(config["weight"]) > 0 ->
          "#{base} · +#{format_number(config["weight"])} #{state["unit"]}"

        bodyweight? ->
          base

        true ->
          "#{base} · #{format_number(config["weight"] || 0)} #{state["unit"]}"
      end

    techniques =
      config
      |> routine_set_techniques()
      |> Enum.with_index()
      |> Enum.reject(fn {technique, _index} -> is_nil(technique) end)
      |> Enum.map(fn {technique, index} ->
        name =
          if technique["type"] == "dropset",
            do: t(locale, "Drop-set"),
            else: t(locale, "Rest-pause")

        "#{t(locale, "Set")} #{index + 1}: #{name}"
      end)

    if techniques == [], do: base, else: "#{base} · #{Enum.join(techniques, " · ")}"
  end

  defp routine_exercise_attrs(params) do
    %{
      "sets" => max(1, State.integer(params["sets"], 3)),
      "reps" => max(0, State.integer(params["reps"], 10)),
      "weight" => max(0.0, State.number(params["weight"]))
    }
  end

  defp open_workout_exercise_picker(socket, modal) do
    assign(socket,
      modal: modal,
      search: "",
      body_part: "",
      equipment: "",
      catalogue_results: Enum.take(Catalogue.all(), 80)
    )
  end

  defp unfinished_sets(state) do
    case state["active"] do
      nil -> 0
      active -> active["entries"] |> Enum.flat_map(& &1["sets"]) |> Enum.count(&(not &1["done"]))
    end
  end

  defp set_done?(state, entry_index, set_index) do
    entry = state["active"] && Enum.at(state["active"]["entries"], entry_index)
    set = entry && Enum.at(entry["sets"], set_index)
    (set && set["done"]) || false
  end

  defp warmup_set?(state, entry_index, set_index) do
    entry = state["active"] && Enum.at(state["active"]["entries"], entry_index)
    set = entry && Enum.at(entry["sets"], set_index)
    (set && State.warmup_set?(set)) || false
  end

  defp phase_number(sets, set_index) do
    set = Enum.at(sets, set_index)
    warmup? = set && State.warmup_set?(set)

    sets
    |> Enum.take(set_index + 1)
    |> Enum.count(&(State.warmup_set?(&1) == warmup?))
  end

  defp starts_phase?(sets, set_index, warmup?) do
    previous = if set_index > 0, do: Enum.at(sets, set_index - 1)
    set_index == 0 || State.warmup_set?(previous) != warmup?
  end

  defp last_exercise_entry(state, exercise_id) do
    state["workouts"]
    |> Enum.reverse()
    |> Enum.find_value(fn workout ->
      case Enum.find(workout["entries"], &(&1["id"] == exercise_id)) do
        nil ->
          nil

        entry ->
          labels =
            entry["sets"]
            |> Enum.filter(&(&1["done"] && not State.warmup_set?(&1)))
            |> Enum.map(&workout_set_label(state, exercise_id, &1))

          if labels == [], do: nil, else: %{date: workout["d"], label: Enum.join(labels, ", ")}
      end
    end)
  end

  defp workout_set_label(state, exercise_id, set) do
    item = exercise(state, exercise_id)
    bodyweight? = item && item["eq"] == "body weight"
    weight = State.number(set["w"])
    reps = State.integer(set["r"], 0)

    if bodyweight? && weight <= 0,
      do: "#{reps} #{t(State.locale(state), "reps")}",
      else: "#{format_number(weight)} #{state["unit"]} × #{reps}"
  end

  defp persist(socket, state) do
    state = Map.put(state, "_ts", System.system_time(:millisecond))

    socket =
      socket
      |> assign(:state, state)
      |> assign(:locale, State.locale(state))

    case socket.assigns.current_scope do
      %{local_only?: true} ->
        push_event(socket, "guest:save", %{state: state})

      %{user: user} ->
        case Gym.put_data(user, state) do
          {:ok, :ok} -> socket
          {:error, _reason} -> put_flash(socket, :error, "Could not save your changes.")
        end

      _scope ->
        socket
    end
  end

  defp apply_preferences(socket) do
    state = socket.assigns.state

    push_event(socket, "prefs:apply", %{
      theme: state["theme"] || "dark",
      accent: state["accent"] || "lime",
      language: State.locale(state)
    })
  end

  defp preference(%{"key" => key, "value" => value}) when key in ~w(restSec restPauseSec),
    do: {key, max(0, State.integer(value, if(key == "restSec", do: 90, else: 15)))}

  defp preference(%{"key" => "unit", "value" => value}) when value in ~w(kg lb),
    do: {"unit", value}

  defp preference(%{"key" => "lang", "value" => value}) when value in ~w(en es),
    do: {"lang", value}

  defp preference(%{"key" => "theme", "value" => value}) when value in ~w(dark light system),
    do: {"theme", value}

  defp preference(%{"key" => "accent", "value" => value})
       when value in ~w(lime sky orange violet pink red teal gold),
       do: {"accent", value}

  defp preference(_params), do: {"unit", "kg"}

  defp setting_options("lang", locale) do
    [
      %{value: "en", label: t(locale, "English")},
      %{value: "es", label: t(locale, "Spanish")}
    ]
  end

  defp setting_options("restSec", locale) do
    [%{value: 0, label: t(locale, "Off")} | seconds_options([60, 90, 120, 150, 180])]
  end

  defp setting_options("restPauseSec", _locale), do: seconds_options([10, 15, 20, 30])
  defp setting_options(_key, _locale), do: []

  defp seconds_options(values), do: Enum.map(values, &%{value: &1, label: "#{&1}s"})

  defp setting_title("lang", locale), do: t(locale, "Language")
  defp setting_title("restSec", locale), do: t(locale, "Rest timer")
  defp setting_title("restPauseSec", locale), do: t(locale, "Rest-pause rest")
  defp setting_title(_key, _locale), do: ""

  defp seconds_label(value, locale) do
    case State.integer(value, 0) do
      0 -> t(locale, "Off")
      seconds -> "#{seconds}s"
    end
  end

  defp language_name("es", locale), do: t(locale, "Spanish")
  defp language_name(_language, locale), do: t(locale, "English")

  defp ai_goal_options(locale) do
    [
      {t(locale, "Strength"), "strength"},
      {t(locale, "Hypertrophy"), "hypertrophy"},
      {t(locale, "General fitness"), "general_fitness"},
      {t(locale, "Fat loss"), "fat_loss"}
    ]
  end

  defp ai_muscle_group_options(locale) do
    Enum.map(AIPlanner.muscle_groups(), fn group ->
      %{value: group, label: t(locale, muscle_group_label(group))}
    end)
  end

  defp muscle_group_label("chest"), do: "Chest"
  defp muscle_group_label("back"), do: "Back"
  defp muscle_group_label("shoulders"), do: "Shoulders"
  defp muscle_group_label("legs"), do: "Legs"
  defp muscle_group_label("biceps"), do: "Biceps"
  defp muscle_group_label("triceps"), do: "Triceps"
  defp muscle_group_label("core"), do: "Core"

  defp ai_alternative_reason_options(locale) do
    [
      %{value: "equipment", label: t(locale, "Equipment unavailable")},
      %{value: "pain", label: t(locale, "Pain or discomfort")},
      %{value: "occupied", label: t(locale, "Equipment is occupied")},
      %{value: "too_difficult", label: t(locale, "Too difficult today")},
      %{value: "other", label: t(locale, "Other reason")}
    ]
  end

  defp selected_ai_model(state, models) do
    if state["aiModel"] in models, do: state["aiModel"], else: List.first(models)
  end

  defp ai_error_message(locale) do
    t(locale, "The AI service could not create a valid result. Please try again.")
  end

  defp ai_technique_label(
         %{"last_set_technique" => %{"type" => "dropset"} = technique},
         locale
       ) do
    "#{t(locale, "Last set")}: #{t(locale, "Drop-set")} · #{technique["count"]} × -#{technique["pct"]}%"
  end

  defp ai_technique_label(
         %{"last_set_technique" => %{"type" => "restpause"} = technique},
         locale
       ) do
    "#{t(locale, "Last set")}: #{t(locale, "Rest-pause")} · +#{technique["totalReps"]} reps · #{technique["restSec"]}s"
  end

  defp ai_technique_label(_prescription, _locale), do: nil

  defp accent_options do
    [
      %{key: "lime", label: "Lime", color: "#30d158"},
      %{key: "sky", label: "Sky", color: "#0a84ff"},
      %{key: "orange", label: "Orange", color: "#ff9f0a"},
      %{key: "violet", label: "Violet", color: "#bf5af2"},
      %{key: "pink", label: "Pink", color: "#ff375f"},
      %{key: "red", label: "Red", color: "#ff453a"},
      %{key: "teal", label: "Teal", color: "#40c8e0"},
      %{key: "gold", label: "Gold", color: "#ffd60a"}
    ]
  end

  defp page_title(:home, locale), do: t(locale, "Home")
  defp page_title(:plan, locale), do: t(locale, "Plan")
  defp page_title(:routine, locale), do: t(locale, "Routines")
  defp page_title(:workout, locale), do: t(locale, "Workout")
  defp page_title(:stats, locale), do: t(locale, "Stats")
  defp page_title(:history, locale), do: t(locale, "History")
  defp page_title(:library, locale), do: t(locale, "Exercises")
  defp page_title(:settings, locale), do: t(locale, "Settings")

  defp days("es"), do: @days_es
  defp days(_locale), do: @days_en

  defp date_label("es", date) do
    weekdays = ~w(lunes martes miércoles jueves viernes sábado domingo)

    months =
      ~w(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)

    "#{Enum.at(weekdays, Date.day_of_week(date) - 1)}, #{date.day} de #{Enum.at(months, date.month - 1)}"
  end

  defp date_label(_locale, date), do: Calendar.strftime(date, "%A, %B %-d")

  defp short_date_label(locale, iso) when is_binary(iso) do
    case Date.from_iso8601(iso) do
      {:ok, date} -> short_date_label(locale, date)
      _error -> iso
    end
  end

  defp short_date_label("es", date) do
    months = ~w(ene feb mar abr may jun jul ago sep oct nov dic)
    "#{date.day} #{Enum.at(months, date.month - 1)}"
  end

  defp short_date_label(_locale, date), do: Calendar.strftime(date, "%b %-d")

  defp weight_delta_class(_delta, _current, nil), do: "weight-neutral"

  defp weight_delta_class(delta, current, target) do
    moving_up? = delta > 0
    goal_is_up? = State.number(target) > State.number(current)
    if moving_up? == goal_is_up?, do: "weight-toward", else: "weight-away"
  end

  defp goal_progress_label(locale, target, current, unit) do
    difference = abs(State.number(target) - State.number(current))

    cond do
      difference < 0.05 ->
        "#{t(locale, "Goal")} #{format_number(target)} #{unit} · #{t(locale, "reached!")}"

      State.number(target) > State.number(current) ->
        "#{t(locale, "Goal")} #{format_number(target)} #{unit} · #{format_number(difference)} #{unit} #{t(locale, "to gain")}"

      true ->
        "#{t(locale, "Goal")} #{format_number(target)} #{unit} · #{format_number(difference)} #{unit} #{t(locale, "to lose")}"
    end
  end

  defp modal_info(:bodyweight), do: {:bodyweight, nil}
  defp modal_info({:bodyweight_start, _routine_id}), do: {:bodyweight_start, nil}
  defp modal_info(:goal), do: {:goal, nil}
  defp modal_info(:ai_week), do: {:ai_week, nil}
  defp modal_info(:ai_week_loading), do: {:ai_week_loading, nil}
  defp modal_info(:ai_week_preview), do: {:ai_week_preview, nil}
  defp modal_info({:ai_day, day}), do: {:ai_day, day}
  defp modal_info({:ai_day_loading, day}), do: {:ai_day_loading, day}
  defp modal_info({:ai_day_preview, day}), do: {:ai_day_preview, day}
  defp modal_info(:ai_model), do: {:ai_model, nil}
  defp modal_info({:ai_alternative_reason, index}), do: {:ai_alternative_reason, index}
  defp modal_info({:ai_alternatives, index}), do: {:ai_alternatives, index}
  defp modal_info(:custom_exercise), do: {:custom_exercise, nil}
  defp modal_info(:stats_exercise), do: {:stats_exercise, nil}
  defp modal_info(:workout_exercise), do: {:workout_exercise, nil}
  defp modal_info(:finish_workout), do: {:finish_workout, nil}
  defp modal_info(:discard_workout), do: {:discard_workout, nil}
  defp modal_info(:sign_out), do: {:sign_out, nil}
  defp modal_info({:setting, key}), do: {:setting, key}

  defp modal_info({:routine_exercise_picker, routine_id}),
    do: {:routine_exercise_picker, routine_id}

  defp modal_info({:routine_exercise, routine_id, index}),
    do: {:routine_exercise, {routine_id, index}}

  defp modal_info({:swap_exercise, index}), do: {:swap_exercise, index}
  defp modal_info({:remove_exercise, index}), do: {:remove_exercise, index}
  defp modal_info({:exercise, id}), do: {:exercise, id}
  defp modal_info({:add_exercise, id}), do: {:add_exercise, id}
  defp modal_info({:day_schedule, day}), do: {:day_schedule, day}
  defp modal_info({:day_override, date}), do: {:day_override, date}
  defp modal_info({:workout, id}), do: {:workout, id}
  defp modal_info({:activity, date}), do: {:activity, date}

  defp routine_for_day(state, day) do
    routine_id = state["week"][to_string(day)] || state["week"][day]
    Enum.find(state["routines"], &(&1["id"] == routine_id))
  end

  defp routine_for_weekly_date(state, date) do
    routine_for_day(state, Integer.to_string(rem(Date.day_of_week(date), 7)))
  end

  defp parse_date(iso) do
    case Date.from_iso8601(to_string(iso)) do
      {:ok, date} -> date
      _error -> nil
    end
  end

  defp day_name(locale, day) do
    day = to_string(day)
    days(locale) |> Enum.find_value(fn {name, value} -> if value == day, do: name end)
  end

  defp exercise(state, id) do
    Enum.find(state["customEx"], &(&1["id"] == id)) || Catalogue.get(id)
  end

  defp exercise_name(state, id) do
    case exercise(state, id) do
      nil -> "Unknown exercise"
      exercise -> exercise["n"]
    end
  end

  defp filtered_catalogue(assigns, limit) do
    assigns.search
    |> Catalogue.search(length(Catalogue.all()))
    |> Enum.filter(fn exercise ->
      assigns.body_part == "" || exercise["bp"] == assigns.body_part
    end)
    |> Enum.filter(fn exercise ->
      assigns.equipment == "" || exercise["eq"] == assigns.equipment
    end)
    |> Enum.take(limit)
  end

  defp catalogue_equipment(search, body_part) do
    search
    |> Catalogue.search(length(Catalogue.all()))
    |> Enum.filter(fn exercise -> body_part == "" || exercise["bp"] == body_part end)
    |> Enum.map(& &1["eq"])
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {equipment, count} -> {-count, equipment} end)
    |> Enum.map(&elem(&1, 0))
  end

  defp exercise_thumbnail(state, exercise_id) do
    case exercise(state, exercise_id) do
      %{"img" => image} when is_binary(image) and image != "" -> "/img/#{image}"
      _exercise -> "/images/icon.svg"
    end
  end

  defp weight_in_range(rows, 0, _today), do: rows

  defp weight_in_range(rows, days, today) do
    cutoff = Date.add(today, -days)
    Enum.filter(rows, &date_on_or_after?(&1["d"], cutoff))
  end

  defp weight_delta(rows, today) do
    case weight_in_range(rows, 30, today) |> Enum.sort_by(& &1["d"]) do
      [_only] -> nil
      [] -> nil
      filtered -> State.number(List.last(filtered)["w"]) - State.number(List.first(filtered)["w"])
    end
  end

  defp signed_number(value) when value > 0, do: "+#{format_number(value)}"
  defp signed_number(value), do: format_number(value)

  defp activity_days(state, today) do
    counts = Enum.frequencies_by(state["workouts"], & &1["d"])

    for offset <- -363..0 do
      date = Date.add(today, offset)
      count = Map.get(counts, Date.to_iso8601(date), 0)

      level =
        cond do
          count == 0 -> 0
          count == 1 -> 2
          count == 2 -> 3
          true -> 4
        end

      %{date: Date.to_iso8601(date), count: count, level: level}
    end
  end

  defp muscle_balance(state, today) do
    cutoff = Date.add(today, -30)

    loads =
      state["workouts"]
      |> Enum.filter(&date_on_or_after?(&1["d"], cutoff))
      |> Enum.flat_map(& &1["entries"])
      |> Enum.reduce(%{}, fn entry, totals ->
        count = Enum.count(entry["sets"], &(&1["done"] && not State.warmup_set?(&1)))
        item = exercise(state, entry["id"])
        muscle = (item && (item["tg"] || item["bp"])) || "other"
        if count > 0, do: Map.update(totals, muscle, count, &(&1 + count)), else: totals
      end)

    maximum = loads |> Map.values() |> Enum.max(fn -> 1 end)

    loads
    |> Enum.sort_by(fn {name, sets} -> {-sets, name} end)
    |> Enum.take(7)
    |> Enum.map(fn {name, sets} ->
      %{name: name, sets: sets, percent: round(sets / maximum * 100)}
    end)
  end

  defp stats_exercise_ids(state) do
    state["workouts"]
    |> Enum.flat_map(& &1["entries"])
    |> Enum.map(& &1["id"])
    |> Enum.uniq()
  end

  defp exercise_progress(_state, nil), do: []

  defp exercise_progress(state, exercise_id) do
    entries =
      for workout <- state["workouts"],
          entry <- workout["entries"],
          entry["id"] == exercise_id,
          do: {workout, entry}

    loaded? =
      Enum.any?(entries, fn {_workout, entry} ->
        Enum.any?(
          entry["sets"],
          &(&1["done"] && not State.warmup_set?(&1) && State.number(&1["w"]) > 0)
        )
      end)

    entries
    |> Enum.map(fn {workout, entry} ->
      done = Enum.filter(entry["sets"], &(&1["done"] && not State.warmup_set?(&1)))

      value =
        if loaded?,
          do: Enum.map(done, &State.number(&1["w"])) |> Enum.max(fn -> 0.0 end),
          else: Enum.map(done, &State.integer(&1["r"], 0)) |> Enum.max(fn -> 0 end)

      %{date: workout["d"], value: value, unit: if(loaded?, do: state["unit"], else: "reps")}
    end)
    |> Enum.filter(&(&1.value > 0))
  end

  defp date_on_or_after?(iso, cutoff) do
    case Date.from_iso8601(to_string(iso)) do
      {:ok, date} -> Date.compare(date, cutoff) in [:eq, :gt]
      _error -> false
    end
  end

  defp best_weight(state, exercise_id) do
    state["workouts"]
    |> Enum.flat_map(& &1["entries"])
    |> Enum.filter(&(&1["id"] == exercise_id))
    |> Enum.flat_map(& &1["sets"])
    |> Enum.filter(&(&1["done"] && not State.warmup_set?(&1)))
    |> Enum.map(&State.number(&1["w"]))
    |> Enum.max(fn -> 0.0 end)
  end

  defp week_days(state, today, offset, locale) do
    monday = Date.add(today, -(Date.day_of_week(today) - 1) + offset * 7)
    done_dates = MapSet.new(state["workouts"], & &1["d"])
    labels = if locale == "es", do: ~w(L M X J V S D), else: ~w(Mo Tu We Th Fr Sa Su)

    for index <- 0..6 do
      date = Date.add(monday, index)
      iso = Date.to_iso8601(date)
      override = state["dayPlan"][iso]
      planned = State.effective_routine(state, date)

      kind =
        cond do
          MapSet.member?(done_dates, iso) -> "done"
          override && planned -> "ovr"
          planned -> "plan"
          true -> nil
        end

      %{date: date, label: Enum.at(labels, index), today?: date == today, kind: kind}
    end
  end

  defp week_label(_days, 0, locale), do: t(locale, "This week")

  defp week_label(days, _offset, _locale) do
    first = List.first(days).date
    last = List.last(days).date

    "#{first.day} #{Calendar.strftime(first, "%b")} – #{last.day} #{Calendar.strftime(last, "%b")}"
  end

  defp week_start(%Date{} = date), do: Date.add(date, -(Date.day_of_week(date) - 1))

  defp week_start(iso) when is_binary(iso) do
    case Date.from_iso8601(iso) do
      {:ok, date} -> week_start(date)
      _error -> nil
    end
  end

  defp streak_weeks(state) do
    trained = state["workouts"] |> Enum.map(&week_start(&1["d"])) |> MapSet.new()
    current = week_start(Date.utc_today())
    start = if MapSet.member?(trained, current), do: current, else: Date.add(current, -7)

    Stream.iterate(start, &Date.add(&1, -7))
    |> Enum.reduce_while(0, fn week, count ->
      if MapSet.member?(trained, week), do: {:cont, count + 1}, else: {:halt, count}
    end)
  end

  defp greeting(%{local_only?: true}, _locale), do: "tamagym"
  defp greeting(%{user: user}, "es"), do: "Hola, #{Accounts.public_user(user).name}"
  defp greeting(%{user: user}, _locale), do: "Hi, #{Accounts.public_user(user).name}"

  defp today_icon(%{"active" => active}, _routine, _done) when not is_nil(active),
    do: "hero-clock"

  defp today_icon(_state, _routine, done) when not is_nil(done), do: "hero-check-circle"
  defp today_icon(_state, routine, _done) when not is_nil(routine), do: "hero-dumbbell"
  defp today_icon(_state, _routine, _done), do: "hero-moon"

  defp today_icon_style(state, routine, done) do
    color =
      cond do
        state["active"] -> "var(--orange)"
        done -> "var(--surface-3)"
        routine -> "var(--acc)"
        true -> "var(--surface-3)"
      end

    "background:#{color}"
  end

  defp today_title(%{"active" => active}, _routine, _done, locale) when not is_nil(active),
    do: "#{active["name"]} — #{t(locale, "in progress")}"

  defp today_title(_state, _routine, done, _locale) when not is_nil(done),
    do: done["name"] || "Workout done"

  defp today_title(_state, routine, _done, _locale) when not is_nil(routine), do: routine["name"]
  defp today_title(_state, _routine, _done, locale), do: t(locale, "Rest day")

  defp chart_points(rows, goal) do
    values = Enum.map(rows, &State.number(&1["w"]))
    {minimum, maximum} = chart_range(values, if(is_nil(goal), do: nil, else: State.number(goal)))
    count = length(values)
    days = Enum.map(rows, &chart_day(&1["d"]))
    first_day = List.first(days)
    last_day = List.last(days)
    dated? = count > 1 && first_day && last_day && last_day != first_day && Enum.all?(days)

    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      value = State.number(row["w"])

      fraction =
        if dated?,
          do: (Enum.at(days, index) - first_day) / (last_day - first_day),
          else: if(count <= 1, do: 0.5, else: index / (count - 1))

      %{
        x: Float.round(34 + fraction * 294, 1),
        y: Float.round(chart_y(value, minimum, maximum), 1),
        date: row["d"] || "",
        value: value
      }
    end)
  end

  defp chart_y_ticks(rows, goal) do
    values = Enum.map(rows, &State.number(&1["w"]))
    {minimum, maximum} = chart_range(values, if(is_nil(goal), do: nil, else: State.number(goal)))
    raw_step = (maximum - minimum) / 3
    power = :math.pow(10, :math.floor(:math.log10(raw_step)))
    step = Enum.find([1, 2, 2.5, 5, 10], 10, &(raw_step <= &1 * power)) * power
    first = :math.ceil(minimum / step) * step

    Stream.iterate(first, &(&1 + step))
    |> Enum.take_while(&(&1 <= maximum + step / 100))
    |> Enum.map(&%{y: chart_y(&1, minimum, maximum), label: format_number(&1)})
  end

  defp chart_x_ticks(dots, _locale) when length(dots) < 2, do: []

  defp chart_x_ticks(dots, locale) do
    last_index = length(dots) - 1

    [0, div(last_index, 2), last_index]
    |> Enum.uniq()
    |> Enum.map(fn index ->
      point = Enum.at(dots, index)

      anchor =
        if index == 0, do: "start", else: if(index == last_index, do: "end", else: "middle")

      %{x: point.x, label: chart_date_label(locale, point.date), anchor: anchor}
    end)
  end

  defp chart_day(iso) do
    case Date.from_iso8601(to_string(iso)) do
      {:ok, date} -> Date.to_gregorian_days(date)
      _error -> nil
    end
  end

  defp chart_date_label(locale, iso) do
    case Date.from_iso8601(to_string(iso)) do
      {:ok, date} -> short_date_label(locale, date)
      _error -> iso
    end
  end

  defp chart_goal(_rows, nil), do: nil

  defp chart_goal(rows, goal) do
    values = Enum.map(rows, &State.number(&1["w"]))
    {minimum, maximum} = chart_range(values, State.number(goal))
    chart_y(State.number(goal), minimum, maximum)
  end

  defp chart_range(values, goal) do
    values = if is_nil(goal), do: values, else: [goal | values]
    minimum = Enum.min(values, fn -> 0.0 end)
    maximum = Enum.max(values, fn -> 1.0 end)
    padding = max((maximum - minimum) * 0.15, 1.0)
    {minimum - padding, maximum + padding}
  end

  defp chart_y(value, minimum, maximum),
    do: 10 + (1 - (value - minimum) / (maximum - minimum)) * 105

  defp format_number(number) do
    number = State.number(number)

    if number == trunc(number),
      do: Integer.to_string(trunc(number)),
      else: :erlang.float_to_binary(number, decimals: 1)
  end
end
