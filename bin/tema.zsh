#!/bin/zsh

DIR_SCRIPT="${0:A:h}"
LIB="$DIR_SCRIPT/../lib"
export FZF_DEFAULT_OPTS_FILE=~/.config/fzf/fzfrc

. $LIB/vars.zsh
. $LIB/funcs.zsh

cd 

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

trap "restaurar_mantener_cambios; limpieza" EXIT
trap "restaurar_mantener_cambios; limpieza; exit 1" ERR INT

case $comando in
 zsh|tema) 

    CONF_PATH="${ZDOTDIR}/.zshrc"
    DIRS="$ZSH/themes $ZSH/custom/themes"
    FAVLIST="${ZDOTDIR}/.zsh_favlist"
    USED=$( 
      grep -Po "ZSH_THEME=(\S+)" $CONF_PATH | sed -E "s/.*=//g" 
    )
     ;;

  fuente) 
    CONF_PATH="${HOME}/.termux/font.ttf"
    USED_FILE="${USED_PATH}/used_font.log"
    DIRS="$HOME/.fonts"
    FAVLIST="${ZDOTDIR}/.font_favlist"
    EXTENSION="ttf"
    ESPERA="sleep 2 ;"
    ;;

  color) 
    CONF_PATH="${HOME}/.termux/colors.properties"
    USED_FILE="${USED_PATH}/used_color.log"
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
    USED_FILE="${USED_PATH}/used_color.log"
    DIRS="$HOME/.colorscheme"
    EXTENSION="colors"
    MULTI="--multi"
     ;;

  *) 
    ayuda 1 ;;  
esac

export DIRS CONF_PATH EXTENSION USED USED_FILE FAVLIST ZSH 

USED="${USED:-$(bat -p "$USED_FILE")}"
export USED="${USED:t:r}"

if [[ -n $USADO ]] 
then
  echo "usado: $USED" 
  exit 0
fi

# definir o reemplazar funciones existentes
case $comando in
  zsh|tema) 
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

        echo -e "${CHOICE}" > $USED_FILE
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

