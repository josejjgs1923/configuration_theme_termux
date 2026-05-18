#!/bin/zsh

cd 

USED_PATH="${HOME}/.config/mytermux"

ayuda() {
  less -FERX <<- HELP
  uso: ${ZSH_ARGZERO:t} comando <query>
  herramienta para personalizar la terminal.
  comandos:
  help             mostrar esta ayuda y salir.
  tema, zsh        configurar tema del prompt.
  fuente           cambiar fuente de la terminal
  color            cambiar colores de la terminal
  descargar        descargar nuevos temas de color, desde Gogh4Termux.
  usado [estilo]   mostrar configuracion estilo
                   los estilos son los mismos comandos.
HELP
	exit "$1"
}

comandos=( tema zsh color descargar fuente usado help --help -h  )

# comparar con comandos aceptados, imprimir mas parecido, o dejar vacio

comando="${comandos[(r)${1}*]}"

[[ -z "$1" ]] && ayuda 1

shift || ayuda 1

case $comando in
  help|--help|-h)
    ayuda 0 
    ;;
  usado)
    USADO=1
    comando="${comandos[(r)${1}*]}"
  ;;
esac

restaurar_mantener_cambios()
{
  if [[ -f "$modo_conf" ]]
  then
    if  [[ $(bat -p "$modo_conf") == 1 ]]
    then
      mv "${CONF_PATH}.bck"  "$CONF_PATH"
      termux-reload-settings
    else
      rm "${CONF_PATH}.bck"
    fi
  fi
}

limpieza()
{
  rm -f "$modo" 
  rm -f "$modo_conf"
}

trap "restaurar_mantener_cambios; limpieza" EXIT
trap "restaurar_mantener_cambios; limpieza; exit 1" ERR INT

SHORTCUT_SALVAR="ctrl-a"
SHORTCUT_GUARDAR_FAV="ctrl-g"
SHORTCUT_ALTERNAR_FAV="ctrl-f"
SHORTCUT_ALTERNAR_PREVIEW="ctrl-o"

case $comando in
 zsh|tema) 

    CONF_PATH="${ZDOTDIR}/.zshrc"
    USED_FILE="${USED_PATH}/zsh/used.log"
    DIRS="$ZSH/themes $ZSH/custom/themes"
    FAVLIST="${ZDOTDIR}/.zsh_favlist"
    export ZSH_CONFIGURATION_THEME_USED=$( 
      grep -Po "ZSH_THEME=(\S+)" $CONF_PATH | sed -E "s/.*=//g" 
    )
     ;;

  fuente) 
    CONF_PATH="${HOME}/.termux/font.ttf"
    USED_FILE="${USED_PATH}/fonts/used.log"
    DIRS="$HOME/.fonts"
    FAVLIST="${ZDOTDIR}/.font_favlist"
    EXTENSION="ttf"
    ESPERA="sleep 2 ;"
    ;;

  color) 
    CONF_PATH="${HOME}/.termux/colors.properties"
    USED_FILE="${USED_PATH}/colorscheme/used.log"
    DIRS="$HOME/.colorscheme"
    FAVLIST="${ZDOTDIR}/.color_favlist"
    EXTENSION="colors"
     ;;

  descargar) 
    URL_GITHUB=https://github.com/AvinashReddy3108/Gogh4Termux
    URL_TEMAS=https://api.github.com/repos/AvinashReddy3108/Gogh4Termux/git/trees/master
    export URL_BASE_TEMA=https://raw.githubusercontent.com/AvinashReddy3108/Gogh4Termux/master

    status_code=$(
      curl -s -o /dev/null -I -w "%{http_code}"  "$URL_GITHUB"
    )

    if [[ ! "$status_code" -eq "200" ]]
    then
      echo "No se puede alcanzar el repositorio. Asegurese de estar conectado a internet"
    fi
    CONF_PATH="${HOME}/.termux/colors.properties"
    USED_FILE="${USED_PATH}/colorscheme/used.log"
    DIRS="$HOME/.colorscheme"
    EXTENSION="colors"
    MULTI="--multi"
     ;;

  *) 
    ayuda 1 ;;  
esac

export DIRS CONF_PATH EXTENSION USED USED_FILE FAVLIST ZSH 

USED="$(bat -p $USED_FILE)"
export USED="${USED:t:r}"

if [[ -n $USADO ]] 
then
  echo "usado: $USED" 
  exit 0
fi

# funciones de base

list_options() {
  find $( printf "$*" ) -maxdepth 1 -type "f,l" -print | sed -E "s/\.[^\/]+$//"
}

export DEF_LIST_OPTIONS="$( declare -f list_options )"

insert_favlist() {

  THEME_NAME="$*"

  if  [[ $(bat -p "$modo") == 1 ]]
  then
    if grep -q "$THEME_NAME" $FAVLIST 2> /dev/null
    then
        echo "change-header($prompt_ya_esta)"
    else
      echo "$THEME_NAME" >> "$FAVLIST" ; 
      sort -o "$FAVLIST" "$FAVLIST"
      echo "change-header($prompt_guardado)"
    fi
  else
    echo "execute(sed -i --follow-symlinks '\\@{}@d' $FAVLIST)+change-header($prompt_eliminado)+reload(bat -p $FAVLIST)"
  fi

}

alternar_favoritos(){ 

  if  [[ $(bat -p "$modo") == 1 ]]
  then 
    echo 0 > "$modo"
    echo "change-header($prompt_favoritas)+reload(bat -p $FAVLIST)"
  else
    echo 1 > "$modo"
    echo "change-header($prompt_global)+reload~
      $DEF_LIST_OPTIONS ; 
      list_options $DIRS ; ~" 
  fi 
}

GUARDAR_FAVORITOS="${SHORTCUT_GUARDAR_FAV}:transform| 
  $( declare -f insert_favlist ) ; 
  insert_favlist {} |"

ALTERNAR_FAVORITOS="${SHORTCUT_ALTERNAR_FAV}:transform% 
$( declare -f alternar_favoritos ) ; 
alternar_favoritos %"

ARGS_BASE=(  
  --bind "${SHORTCUT_ALTERNAR_PREVIEW}:toggle-preview"
  --bind "${ALTERNAR_FAVORITOS}"
  --bind "${GUARDAR_FAVORITOS}"
)

# definir o reemplazar funciones existentes
case $comando in
 zsh|tema) 
    cambiar(){

      CHOICE="$*"
      CHOICE="${CHOICE:t}"

      if sed -i --follow-symlinks\
        "s/ZSH_THEME=${ZSH_CONFIGURATION_THEME_USED}.*/ZSH_THEME=${CHOICE}/g"\
        ${CONF_PATH}; then
        if [ ! -f ${USED_FILE} ]; then

          echo -e "${CHOICE}" >> $USED_FILE

        elif [ -f $USED_FILE ]; then

          sed -i --follow-symlinks "s/${USED}/${CHOICE}/g" $USED_FILE

        fi
      fi
    }

    preview() {
        source $ZSH/oh-my-zsh.sh
       
        THEME_PATH=$1".zsh-theme"
        THEME_NAME="${THEME_PATH:t:r}"

        print "$fg[blue]${(l.((${COLUMNS}-${#THEME_NAME}-5))..─.)}$reset_color $THEME_NAME $fg[blue]───$reset_color"

        source "$THEME_PATH" 
      
        cols=$(tput cols)
        (exit 1)
        print -P "$PROMPT                                                                                      $RPROMPT"
    }

    INGRESAR_CAMBIO="${SHORTCUT_SALVAR}:become@ 
      $( declare -f cambiar ) ; 
      cambiar {}; 
      exec zsh @"

    INGRESAR_PREVIEW="enter:preview|
      $( declare -f preview ) ; 
        preview {} |"

    ARGS_FUNCION=(
      $ARGS_BASE[@]
      --bind "${INGRESAR_PREVIEW}"
      --bind "${INGRESAR_CAMBIO}"
    )
     ;;
  fuente|color) 
    preview() {
      CHOICE="$1"
      cp -fr "${CHOICE}.${EXTENSION}" "$CONF_PATH"
      termux-reload-settings
    }

    cambiar(){

      CHOICE=$1".$EXTENSION"

      if cp -fr "$CHOICE" "$CONF_PATH"; then
        CHOICE=${CHOICE:t:r}
        echo 0 > "$modo_conf"
        if [ ! -f ${USED_FILE} ]; then
          echo -e "${CHOICE}" >> $USED_FILE
        elif [ -f $USED_FILE ]; then
          sed -i --follow-symlinks "s/${USED}/${CHOICE}/g" $USED_FILE
        fi
      fi
    }

    INGRESAR_CAMBIO="${SHORTCUT_SALVAR}:become@ 
      $( declare -f cambiar ) ; 
      cambiar {}; 
      termux-reload-settings @"

    INGRESAR_PREVIEW="enter:execute| 
      $( declare -f preview ) ; 
          preview {}; 
          $ESPERA
          termux-reload-settings |"

    ARGS_FUNCION=(
      $ARGS_BASE[@]
      --bind "${INGRESAR_PREVIEW}"
      --bind "${INGRESAR_CAMBIO}"
    )

    export modo_conf="$(mktemp)"
    echo 1 > "$modo_conf"

    mv "$CONF_PATH" "${CONF_PATH}.bck"
     ;;
  descargar) 
    list_options() {
      curl -fSsL "$URL_TEMAS" | jq -r '.tree[] | select (.path | contains(".properties")) | .path'
    }

    guardar_tema(){
      for tema in "$@"
      do
        curl -fSsL "$URL_BASE_TEMA/$tema" -o "$DIRS/${tema:r}.$EXTENSION"
      done

      echo "descarga terminada."
    }

    GUARDAR_TEMA="enter:become| 
      $( declare -f guardar_tema ) ; 
          guardar_tema {+} |"

    ARGS_FUNCION=(
      --bind "${GUARDAR_TEMA}"
    )
    ;;
esac

export prompt_global="Lista Temas Global"
export prompt_favoritas="Lista Favoritos"  
export prompt_ya_esta="Ya esta en Favoritos"
export prompt_guardado="Guardado en favoritos"  
export prompt_eliminado="Eliminado"  

export modo="$(mktemp)"
echo 1 > "$modo"


list_options "$DIRS" | fzf\
  ${MULTI}\
  --query="$*"\
  --layout=reverse\
  -d "/"\
  --header=$prompt_global\
  --with-nth "-1"\
  --prompt "elegir tema:"\
  --cycle\
  --height="60%"\
  --preview-window="up,35%,hidden"\
  --border=bottom\
  --border-label="tema actual: $USED"\
  ${ARGS_FUNCION[@]} || true

